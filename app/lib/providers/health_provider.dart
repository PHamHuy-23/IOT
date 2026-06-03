import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';
import '../models/health_metrics.dart';
import '../services/ble_service.dart';
import '../services/permission_service.dart';

class HealthProvider extends ChangeNotifier {
  final BleService _bleService = BleService();

  int _heartRate = 0;
  int _spO2 = 0;
  final HeartRateHistory _heartRateHistory = HeartRateHistory(
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
    FlutterBluePlus.events.onConnectionStateChanged.listen((_) {
      notifyListeners();
    });
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

      _connectedDevice = device;
      _isConnected = true;
      _connectionStatus = "Connected to ${device.platformName}";

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
