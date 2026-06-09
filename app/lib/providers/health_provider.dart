import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/ble_constants.dart';
import '../models/health_metrics.dart';
import '../services/ble_service.dart';
import '../services/health_data_service.dart';
import '../services/permission_service.dart';
import '../services/simulated_health_service.dart';

class HealthProvider extends ChangeNotifier {
  static const String _savedWatchIdKey = 'saved_watch_id';
  static const int _maxRetries = 5;
  static const Duration _saveInterval = Duration(seconds: 45);

  final BleService _bleService = BleService();
  final HealthDataService _healthData = HealthDataService();
  final SimulatedHealthService _simulator = SimulatedHealthService();

  StreamSubscription? _connectionStateSubscription;
  int _retryCount = 0;

  int _heartRate = 0;
  int _spO2 = 0;
  bool _fallDetected = false;
  bool _usingSimulatedData = false;
  final HeartRateHistory _heartRateHistory = HeartRateHistory(
    values: [],
    timestamps: [],
  );

  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = "Disconnected";
  BluetoothDevice? _connectedDevice;
  String _errorMessage = "";
  String? Function()? _userIdProvider;
  bool Function()? _simulationModeProvider;
  DateTime? _lastCloudSave;
  VoidCallback? _onDataSaved;
  void Function(int hr, int spo2, bool isSimulated)? _onVitalsAlert;
  void Function(bool isSimulated, int confidence)? _onFallAlert;

  // Getters
  int get heartRate => _heartRate;
  int get spO2 => _spO2;
  bool get fallDetected => _fallDetected;
  bool get usingSimulatedData => _usingSimulatedData;
  HeartRateHistory get heartRateHistory => _heartRateHistory;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get errorMessage => _errorMessage;

  HealthProvider() {
    _initializeStreams();
  }

  void setUserIdProvider(String? Function()? provider) {
    _userIdProvider = provider;
  }

  void setOnDataSaved(VoidCallback? callback) {
    _onDataSaved = callback;
  }

  void setSimulationModeProvider(bool Function()? provider) {
    _simulationModeProvider = provider;
    _syncSimulation();
  }

  void setOnVitalsAlert(
      void Function(int hr, int spo2, bool isSimulated)? callback) {
    _onVitalsAlert = callback;
  }

  void setOnFallAlert(
      void Function(bool isSimulated, int confidence)? callback) {
    _onFallAlert = callback;
  }

  void refreshSimulation() => _syncSimulation();

  void setSimulationScenario(int scenario) {
    _simulator.scenario = scenario;
    _syncSimulation();
  }

  /// Admin/Testing: kích hoạt cảnh báo thủ công
  void triggerTestVitals({required int hr, required int spo2}) {
    _usingSimulatedData = true;
    _updateHeartRate(hr, isSimulated: true);
    _updateSpO2(spo2, isSimulated: true);
    _checkVitalAlert(hr, spo2, isSimulated: true);
  }

  void triggerTestFall({int confidence = 95}) {
    _fallDetected = true;
    _onFallAlert?.call(true, confidence);
    notifyListeners();
  }

  void clearFallState() {
    _fallDetected = false;
    notifyListeners();
  }

  void _syncSimulation() {
    if (_isConnected || !(_simulationModeProvider?.call() ?? false)) {
      _simulator.stop();
      if (!_isConnected) {
        _usingSimulatedData = false;
      }
      return;
    }
    _usingSimulatedData = true;
    _simulator.onPeriodicFall = () {
      _fallDetected = true;
      _onFallAlert?.call(true, 88);
      notifyListeners();
    };
    _simulator.start(onVitals: (hr, spo2) {
      _updateHeartRate(hr, isSimulated: true);
      _updateSpO2(spo2, isSimulated: true);
      _checkVitalAlert(hr, spo2, isSimulated: true);
    });
  }

  void _initializeStreams() {
    FlutterBluePlus.events.onConnectionStateChanged.listen((_) {
      notifyListeners();
    });
  }

  Future<String?> _loadSavedWatchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedWatchIdKey);
  }

  Future<void> _saveWatchId(String watchId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedWatchIdKey, watchId);
  }

  Future<void> autoConnectToWatch() async {
    try {
      _setConnecting(true);
      _errorMessage = "";

      if (!await PermissionService.hasBluetoothPermissions()) {
        final granted =
            await PermissionService.requestBluetoothPermissions();
        if (!granted) {
          _connectionStatus =
              "Cấp quyền Bluetooth và Vị trí cho app trong Cài đặt.";
          _setConnecting(false);
          notifyListeners();
          return;
        }
      }

      final androidIssue = await PermissionService.androidBleReadinessIssue();
      if (androidIssue != null) {
        _connectionStatus = androidIssue;
        _setConnecting(false);
        notifyListeners();
        return;
      }

      final savedWatchId = await _loadSavedWatchId();
      if (savedWatchId != null) {
        _connectionStatus = "Đang kết nối lại với đồng hồ quen...";
        notifyListeners();

        try {
          final device = BluetoothDevice.fromId(savedWatchId);
          await connectToDevice(device);
          return;
        } catch (e) {
          print("Kết nối lại nhanh thất bại, chuyển sang quét mới: $e");
        }
      }

      // Reuse an existing GATT connection if the watch is already connected.
      for (final device in FlutterBluePlus.connectedDevices) {
        if (BleService.isWatchDevice(device)) {
          await connectToDevice(device);
          return;
        }
      }

      // iOS: có thể dùng thiết bị đã ghép. Android: KHÔNG dùng bonded — ghép
      // trong Cài đặt thường báo "không thể giao tiếp với thiết bị".
      if (!Platform.isAndroid) {
        for (final device in await FlutterBluePlus.bondedDevices) {
          if (BleService.isWatchDevice(device)) {
            await connectToDevice(device);
            return;
          }
        }
      }

      _connectionStatus = "Scanning for $TARGET_DEVICE_NAME...";
      notifyListeners();

      final watchDevice = await _bleService.findWatchDevice();
      if (watchDevice == null) {
        _connectionStatus = Platform.isAndroid
            ? "Không thấy $TARGET_DEVICE_NAME. Bật đồng hồ, bật GPS, đứng gần. "
                "Không ghép đôi trong Cài đặt Bluetooth."
            : "$TARGET_DEVICE_NAME not found. Power on the watch and stay nearby.";
        _setConnecting(false);
        notifyListeners();
        return;
      }

      await connectToDevice(watchDevice);
    } catch (e) {
      _errorMessage = e.toString();
      _connectionStatus = "Connection failed: $e";
      _setConnecting(false);
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _setConnecting(true);
      _errorMessage = "";
      _connectionStatus = "Connecting...";
      notifyListeners();

      await _bleService.connectToDevice(device);
      await _saveWatchId(device.remoteId.str);

      _connectedDevice = device;
      _isConnected = true;
      _retryCount = 0;
      _connectionStatus = "Connected to ${device.platformName}";

      // Cancel previous subscription if any
      await _connectionStateSubscription?.cancel();
      
      // Listen for disconnection and auto-reconnect
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _connectedDevice = null;
          _connectionStatus = "Mất kết nối, đang thử lại...";
          _heartRate = 0;
          _spO2 = 0;
          _heartRateHistory.clear();
          notifyListeners();

          // Auto-reconnect with retry limit
          Future.delayed(const Duration(seconds: 3), () async {
            if (!_isConnected && !_isConnecting && _retryCount < _maxRetries) {
              _retryCount++;
              print("🔄 Auto-reconnect attempt $_retryCount/$_maxRetries");
              await autoConnectToWatch();
            } else if (_retryCount >= _maxRetries) {
              _connectionStatus = "Kết nối thất bại sau $_maxRetries lần thử. Hãy kết nối lại thủ công.";
              notifyListeners();
              print("✗ Auto-reconnect exceeded max retries");
            }
          });
        }
      });

      _simulator.stop();
      _usingSimulatedData = false;
      await _subscribeToHealthMetrics();
      await syncTimeToWatch();

      _setConnecting(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _connectionStatus = "Connection failed";
      _isConnected = false;
      _connectedDevice = null;
      _setConnecting(false);
      notifyListeners();
    }
  }

  Future<void> disconnectDevice() async {
    try {
      _setConnecting(true);
      
      // Cancel connection state subscription
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      
      await _bleService.unsubscribeFromHeartRate();
      await _bleService.unsubscribeFromSpO2();
      await _bleService.disconnectDevice();

      _isConnected = false;
      _connectedDevice = null;
      _connectionStatus = "Disconnected";
      _heartRate = 0;
      _spO2 = 0;
      _heartRateHistory.clear();
      _errorMessage = "";
      _retryCount = 0;
      _fallDetected = false;
      _syncSimulation();

      _setConnecting(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setConnecting(false);
      notifyListeners();
    }
  }

  Future<void> _subscribeToHealthMetrics() async {
    final hrStream = await _bleService.subscribeToHeartRate();
    if (hrStream != null) {
      hrStream.listen((data) {
        int bpm = _bleService.parseHeartRate(data);
        _updateHeartRate(bpm);
      }).onError((e) {
        print("Heart rate stream error: $e");
      });
    }

    final spo2Stream = await _bleService.subscribeToSpO2();
    if (spo2Stream != null) {
      spo2Stream.listen((data) {
        int spo2 = _bleService.parseSpO2(data);
        _updateSpO2(spo2, isSimulated: false);
        if (_heartRate > 0 && spo2 > 0) {
          _checkVitalAlert(_heartRate, spo2, isSimulated: false);
        }
      }).onError((e) {
        print("SpO2 stream error: $e");
      });
    }

    final fallStream = await _bleService.subscribeToFallDetection();
    if (fallStream != null) {
      fallStream.listen((data) {
        if (_bleService.parseFallEvent(data)) {
          _fallDetected = true;
          final confidence = _bleService.parseFallConfidence(data);
          _onFallAlert?.call(false, confidence);
          notifyListeners();
        }
      }).onError((e) {
        print("Fall stream error: $e");
      });
    }
  }

  void _updateHeartRate(int bpm, {bool isSimulated = false}) {
    _heartRate = bpm;
    if (!isSimulated) _usingSimulatedData = false;

    if (bpm > 0) {
      _heartRateHistory.add(bpm, DateTime.now());

      if (_heartRateHistory.length > HEART_RATE_HISTORY_MAX_POINTS) {
        _heartRateHistory.values.removeAt(0);
        _heartRateHistory.timestamps.removeAt(0);
      }
    }

    if (!isSimulated) _maybeSaveToCloud();
    notifyListeners();
  }

  void _updateSpO2(int spo2, {bool isSimulated = false}) {
    _spO2 = spo2;
    if (!isSimulated) {
      _usingSimulatedData = false;
      _maybeSaveToCloud();
    }
    notifyListeners();
  }

  void _checkVitalAlert(int hr, int spo2, {required bool isSimulated}) {
    if (hr <= 0 || spo2 <= 0) return;
    _onVitalsAlert?.call(hr, spo2, isSimulated);
  }

  Future<void> _maybeSaveToCloud() async {
    final userId = _userIdProvider?.call();
    if (userId == null || !_isConnected || _usingSimulatedData) return;
    if (_heartRate <= 0 || _spO2 <= 0) return;

    final now = DateTime.now();
    if (_lastCloudSave != null &&
        now.difference(_lastCloudSave!) < _saveInterval) {
      return;
    }

    try {
      await _healthData.saveHealthRecord(
        userId: userId,
        heartRate: _heartRate,
        spo2: _spO2,
        timestamp: now,
      );
      _lastCloudSave = now;
      _onDataSaved?.call();
    } catch (e) {
      debugPrint('[HealthProvider] Cloud save failed: $e');
    }
  }

  Future<void> syncTimeToWatch() async {
    try {
      if (!_isConnected) {
        throw Exception("Device not connected");
      }

      _errorMessage = "";
      await _bleService.syncTime(DateTime.now());
      notifyListeners();
    } catch (e) {
      _errorMessage = "Time sync failed: $e";
      notifyListeners();
    }
  }

  void _setConnecting(bool value) {
    _isConnecting = value;
  }

  @override
  void dispose() {
    _simulator.stop();
    _connectionStateSubscription?.cancel();
    if (_isConnected) {
      disconnectDevice();
    }
    super.dispose();
  }
}
