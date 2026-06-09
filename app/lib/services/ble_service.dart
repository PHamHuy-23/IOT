import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';

class BleService {
  static final BleService _instance = BleService._internal();

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _discoveredServices;
  BluetoothCharacteristic? _heartRateChar;
  BluetoothCharacteristic? _spo2Char;
  BluetoothCharacteristic? _timeSyncChar;
  BluetoothCharacteristic? _fallChar;

  bool isConnected() => _connectedDevice != null;

  BluetoothDevice? getConnectedDevice() => _connectedDevice;

  List<BluetoothService>? getDiscoveredServices() => _discoveredServices;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> _ensureAdapterOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw Exception("Bluetooth is off. Please enable Bluetooth.");
    }
  }

  static bool isWatchAdvertisement(ScanResult result) {
    final advName = result.advertisementData.advName;
    final platformName = result.device.platformName;
    return advName == TARGET_DEVICE_NAME || platformName == TARGET_DEVICE_NAME;
  }

  static bool isWatchDevice(BluetoothDevice device) {
    return device.platformName == TARGET_DEVICE_NAME;
  }

  /// Scan for ESP32C3-Watch by advertisement name (works without system pairing).
  Future<BluetoothDevice?> findWatchDevice({
    Duration timeout = const Duration(seconds: SCAN_TIMEOUT_SECONDS),
  }) async {
    await _ensureAdapterOn();
    await stopScan();

    final completer = Completer<BluetoothDevice?>();
    late final StreamSubscription<List<ScanResult>> subscription;

    subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (!isWatchAdvertisement(result)) {
          continue;
        }
        if (!completer.isCompleted) {
          completer.complete(result.device);
        }
        return;
      }
    });

    try {
      print("🔍 Scanning for $TARGET_DEVICE_NAME...");
      // Một số máy Android không trả kết quả khi dùng withNames.
      if (Platform.isAndroid) {
        await FlutterBluePlus.startScan(timeout: timeout);
      } else {
        await FlutterBluePlus.startScan(
          withNames: [TARGET_DEVICE_NAME],
          timeout: timeout,
        );
      }

      return await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );
    } finally {
      await subscription.cancel();
      await stopScan();
    }
  }

  Future<void> startScan() async {
    try {
      print("🔍 Starting BLE scan...");
      await _ensureAdapterOn();

      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: SCAN_TIMEOUT_SECONDS),
      );
    } catch (e) {
      print("✗ Start scan error: $e");
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      print("✗ Stop scan error: $e");
      rethrow;
    }
  }

  Future<void> getSystemPairedDevices() async {
    try {
      print("🔍 Fetching bonded devices from system...");

      List<BluetoothDevice> devices = await FlutterBluePlus.bondedDevices;
      print("✓ Found ${devices.length} connected devices");

      for (var device in devices) {
        print("  📱 ${device.platformName}");
      }
    } catch (e) {
      print("✗ Error fetching bonded devices: $e");
      rethrow;
    }
  }

  Future<List<BluetoothDevice>> getConnectedSystemDevices() async {
    try {
      return await FlutterBluePlus.bondedDevices;
    } catch (e) {
      print("✗ Error getting connected devices: $e");
      rethrow;
    }
  }

  Future<void> _clearAndroidBondIfAny(BluetoothDevice device) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      final bond = await device.bondState.first
          .timeout(const Duration(seconds: 2));
      if (bond == BluetoothBondState.bonded) {
        print("🔓 Removing stale Android bond before GATT connect...");
        await device.removeBond();
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } catch (e) {
      print("Bond clear skipped: $e");
    }
  }

  Future<void> _gattConnect(BluetoothDevice device) async {
    await device.connect(
      autoConnect: false,
      timeout: const Duration(seconds: DEVICE_CONNECT_TIMEOUT_SECONDS),
    );
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await _ensureAdapterOn();
      await stopScan();

      final displayName = device.platformName.isEmpty
          ? TARGET_DEVICE_NAME
          : device.platformName;
      print("🔗 Connecting to: $displayName");

      // Ghép đôi trong Cài đặt Bluetooth Android thường tạo bond lỗi với ESP32.
      await _clearAndroidBondIfAny(device);

      try {
        await _gattConnect(device);
      } catch (e) {
        if (!Platform.isAndroid) {
          rethrow;
        }
        print("↻ GATT connect failed, retry after removeBond: $e");
        try {
          await device.removeBond();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 800));
        await _gattConnect(device);
      }

      _connectedDevice = device;
      print("✓ Connected successfully");

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (e) {
          print("MTU request skipped: $e");
        }
      }

      await discoverServices();
      await setupCharacteristics();
    } catch (e) {
      print("✗ Connection error: $e");
      _connectedDevice = null;
      rethrow;
    }
  }

  Future<void> disconnectDevice() async {
    try {
      if (_connectedDevice != null) {
        print("🔌 Disconnecting...");
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _discoveredServices = null;
        _heartRateChar = null;
        _spo2Char = null;
        _timeSyncChar = null;
        _fallChar = null;
        print("✓ Disconnected");
      }
    } catch (e) {
      print("✗ Disconnection error: $e");
      rethrow;
    }
  }

  Future<void> discoverServices() async {
    try {
      if (_connectedDevice == null) {
        throw Exception("No connected device");
      }

      print("🔎 Discovering services...");

      List<BluetoothService> services =
          await _connectedDevice!.discoverServices();

      _discoveredServices = services;

      print("✓ Found ${services.length} services:");

      for (var service in services) {
        print("  📋 Service: ${service.uuid}");
        for (var characteristic in service.characteristics) {
          print("     • ${characteristic.uuid}");
        }
      }
    } catch (e) {
      print("✗ Service discovery error: $e");
      rethrow;
    }
  }

  Future<void> setupCharacteristics() async {
    try {
      if (_discoveredServices == null) {
        throw Exception("Services not discovered");
      }

      _heartRateChar = getCharacteristic(
        HEART_RATE_SERVICE_UUID,
        HEART_RATE_MEASUREMENT_UUID,
      );

      _spo2Char = getCharacteristic(
        SPO2_SERVICE_UUID,
        SPO2_MEASUREMENT_UUID,
      );

      _timeSyncChar = getCharacteristic(
        TIME_SYNC_SERVICE_UUID,
        TIME_SYNC_CHARACTERISTIC_UUID,
      );

      _fallChar = getCharacteristic(
        FALL_DETECTION_SERVICE_UUID,
        FALL_EVENT_CHARACTERISTIC_UUID,
      );

      print("✓ Characteristics setup complete");
    } catch (e) {
      print("✗ Characteristic setup error: $e");
      rethrow;
    }
  }

  BluetoothCharacteristic? getCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) {
    if (_discoveredServices == null) return null;

    try {
      var service = _discoveredServices!.firstWhere(
        (s) => _uuidMatches(s.uuid.toString(), serviceUuid),
        orElse: () => throw Exception("Service not found"),
      );

      var characteristic = service.characteristics.firstWhere(
        (c) => _uuidMatches(c.uuid.toString(), characteristicUuid),
        orElse: () => throw Exception("Characteristic not found"),
      );

      return characteristic;
    } catch (e) {
      print(
          "✗ Characteristic lookup failed: serviceUuid=$serviceUuid, charUuid=$characteristicUuid");
      return null;
    }
  }

  bool _uuidMatches(String actual, String expected) {
    String normalize(String uuid) {
      var value = uuid.toLowerCase();
      if (value.length == 4) {
        value = "0000$value-0000-1000-8000-00805f9b34fb";
      }
      return value;
    }

    return normalize(actual) == normalize(expected);
  }

  Future<Stream<List<int>>?> subscribeToHeartRate() async {
    if (_heartRateChar == null) return null;

    try {
      print("📡 Subscribing to heart rate...");
      await _heartRateChar!.setNotifyValue(true);
      return _heartRateChar!.lastValueStream;
    } catch (e) {
      print("✗ Heart rate subscription error: $e");
      return null;
    }
  }

  Future<Stream<List<int>>?> subscribeToFallDetection() async {
    if (_fallChar == null) return null;
    try {
      print("📡 Subscribing to fall detection...");
      await _fallChar!.setNotifyValue(true);
      return _fallChar!.lastValueStream;
    } catch (e) {
      print("✗ Fall detection subscription error: $e");
      return null;
    }
  }

  Future<Stream<List<int>>?> subscribeToSpO2() async {
    if (_spo2Char == null) return null;

    try {
      print("📡 Subscribing to SpO2...");
      await _spo2Char!.setNotifyValue(true);
      return _spo2Char!.lastValueStream;
    } catch (e) {
      print("✗ SpO2 subscription error: $e");
      return null;
    }
  }

  Future<Stream<List<int>>?> subscribeToCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final characteristic = getCharacteristic(serviceUuid, characteristicUuid);
    if (characteristic == null) return null;

    try {
      print("📡 Subscribing to characteristic: $characteristicUuid");
      await characteristic.setNotifyValue(true);
      return characteristic.lastValueStream;
    } catch (e) {
      print("✗ Characteristic subscription error: $e");
      rethrow;
    }
  }

  Future<void> unsubscribeFromHeartRate() async {
    if (_heartRateChar != null) {
      try {
        await _heartRateChar!.setNotifyValue(false);
        print("✓ Heart rate unsubscribed");
      } catch (e) {
        print("✗ Heart rate unsubscribe error: $e");
      }
    }
  }

  Future<void> unsubscribeFromSpO2() async {
    if (_spo2Char != null) {
      try {
        await _spo2Char!.setNotifyValue(false);
        print("✓ SpO2 unsubscribed");
      } catch (e) {
        print("✗ SpO2 unsubscribe error: $e");
      }
    }
  }

  int parseHeartRate(List<int> data) {
    if (data.length < 3) return 0;
    int bpm = data[1] | (data[2] << 8);
    return bpm.clamp(0, MAX_HEART_RATE);
  }

  int parseSpO2(List<int> data) {
    if (data.isEmpty) return 0;
    int spo2 = data[0];
    return spo2.clamp(0, MAX_SPO2);
  }

  bool parseFallEvent(List<int> data) {
    if (data.isEmpty) return false;
    return data[0] == FALL_EVENT_DETECTED;
  }

  int parseFallConfidence(List<int> data) {
    if (data.length < 2) return 100;
    return data[1].clamp(0, 100);
  }

  Future<void> syncTime(DateTime time) async {
    if (_timeSyncChar == null) {
      throw Exception("Time sync characteristic not available");
    }

    try {
      List<int> payload = [
        time.hour,
        time.minute,
        time.second,
      ];

      print("✍️ Syncing time: ${time.hour}:${time.minute}:${time.second}");
      await _timeSyncChar!.write(payload, withoutResponse: true);
      print("✓ Time synced");
    } catch (e) {
      print("✗ Time sync error: $e");
      rethrow;
    }
  }

  Future<List<BluetoothDevice>> scanForDevice() async {
    final device = await findWatchDevice();
    if (device == null) {
      return [];
    }
    return [device];
  }

  Stream<BluetoothConnectionState> get connectionStateStream {
    if (_connectedDevice == null) return const Stream.empty();
    return _connectedDevice!.connectionState;
  }
}
