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

  Stream<List<BluetoothDevice>> get connectedDevices =>
      FlutterBluePlus.connectedDevices;

  bool isConnected() => _connectedDevice != null;

  BluetoothDevice? getConnectedDevice() => _connectedDevice;

  Future<void> getSystemPairedDevices() async {
    try {
      print("🔍 Fetching bonded devices from system...");

      List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;
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
      return await FlutterBluePlus.connectedDevices;
    } catch (e) {
      print("✗ Error getting connected devices: $e");
      rethrow;
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("🔗 Connecting to: ${device.platformName}");

      await device.connect(
        timeout: const Duration(seconds: DEVICE_CONNECT_TIMEOUT_SECONDS),
      );

      _connectedDevice = device;
      print("✓ Connected successfully");

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

  Stream<List<int>>? subscribeToHeartRate() {
    if (_heartRateChar == null) return null;

    try {
      print("📡 Subscribing to heart rate...");
      _heartRateChar!.setNotifyValue(true);
      return _heartRateChar!.lastValueStream;
    } catch (e) {
      print("✗ Heart rate subscription error: $e");
      return null;
    }
  }

  Stream<List<int>>? subscribeToSpO2() {
    if (_spo2Char == null) return null;

    try {
      print("📡 Subscribing to SpO2...");
      _spo2Char!.setNotifyValue(true);
      return _spo2Char!.lastValueStream;
    } catch (e) {
      print("✗ SpO2 subscription error: $e");
      return null;
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
    try {
      print("🔍 Scanning for ESP32C3-Watch...");

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: SCAN_TIMEOUT_SECONDS),
        withConnected: true,
      );

      await for (var result in FlutterBluePlus.scanResults) {
        final matching = result
            .where((r) => r.device.platformName == TARGET_DEVICE_NAME)
            .toList();
        if (matching.isNotEmpty) {
          await FlutterBluePlus.stopScan();
          print("✓ Found ESP32C3-Watch during scan");
          return matching.map((r) => r.device).toList();
        }
      }

      await FlutterBluePlus.stopScan();
      return [];
    } catch (e) {
      print("✗ Scan error: $e");
      return [];
    }
  }
}
