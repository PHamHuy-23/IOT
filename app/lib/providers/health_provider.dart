import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';
import '../models/health_metrics.dart';
import '../services/ble_service.dart';

class HealthProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  int _heartRate = 0;
  int _spO2 = 0;
  HeartRateHistory _heartRateHistory = HeartRateHistory(
    values: [],
    timestamps: [],
  );

  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = "Disconnected";
  BluetoothDevice? _connectedDevice;
  String _errorMessage = "";

  // Getters
  int get heartRate => _heartRate;
  int get spO2 => _spO2;
  HeartRateHistory get heartRateHistory => _heartRateHistory;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get errorMessage => _errorMessage;

  HealthProvider() {
    _initializeStreams();
  }

  void _initializeStreams() {
    _bleService.connectedDevices.listen((devices) {
      notifyListeners();
    });
  }

  Future<void> autoConnectToWatch() async {
    try {
      _setConnecting(true);
      _errorMessage = "";

      List<BluetoothDevice> connectedDevices =
          await _bleService.getConnectedSystemDevices();

      BluetoothDevice? watchDevice;
      for (var device in connectedDevices) {
        if (device.platformName == TARGET_DEVICE_NAME) {
          watchDevice = device;
          break;
        }
      }

      if (watchDevice == null) {
        _connectionStatus = "Device not paired. Please pair via Bluetooth Settings";
        _setConnecting(false);
        notifyListeners();
        return;
      }

      await connectToDevice(watchDevice);
    } catch (e) {
      _errorMessage = e.toString();
      _connectionStatus = "Connection failed";
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

      _connectedDevice = device;
      _isConnected = true;
      _connectionStatus = "Connected to ${device.platformName}";

      _subscribeToHealthMetrics();

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

      _setConnecting(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setConnecting(false);
      notifyListeners();
    }
  }

  void _subscribeToHealthMetrics() {
    final hrStream = _bleService.subscribeToHeartRate();
    if (hrStream != null) {
      hrStream.listen((data) {
        int bpm = _bleService.parseHeartRate(data);
        _updateHeartRate(bpm);
      }).onError((e) {
        print("Heart rate stream error: $e");
      });
    }

    final spo2Stream = _bleService.subscribeToSpO2();
    if (spo2Stream != null) {
      spo2Stream.listen((data) {
        int spo2 = _bleService.parseSpO2(data);
        _updateSpO2(spo2);
      }).onError((e) {
        print("SpO2 stream error: $e");
      });
    }
  }

  void _updateHeartRate(int bpm) {
    _heartRate = bpm;

    if (bpm > 0) {
      _heartRateHistory.add(bpm, DateTime.now());

      if (_heartRateHistory.length > HEART_RATE_HISTORY_MAX_POINTS) {
        _heartRateHistory.values.removeAt(0);
        _heartRateHistory.timestamps.removeAt(0);
      }
    }

    notifyListeners();
  }

  void _updateSpO2(int spo2) {
    _spO2 = spo2;
    notifyListeners();
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
    if (_isConnected) {
      disconnectDevice();
    }
    super.dispose();
  }
}
