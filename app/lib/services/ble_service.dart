import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';

/// Service chính quản lý tất cả các hoạt động BLE
class BleService {
  static final BleService _instance = BleService._internal();

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  // ===== Properties =====
  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _discoveredServices;

  // Streams công khai để lắng nghe sự kiện
  Stream<List<ScanResult>> get scanResults =>
      FlutterBluePlus.scanResults;

  // ===== Scan Methods =====

  /// Bắt đầu quét thiết bị BLE
  Future<void> startScan() async {
    try {
      print("🔍 Bắt đầu quét thiết bị BLE...");

      // Kiểm tra Bluetooth đã bật chưa
      bool isBluetoothOn = await FlutterBluePlus.isSupported;
      if (!isBluetoothOn) {
        throw Exception("Thiết bị không hỗ trợ Bluetooth");
      }

      // Bắt đầu quét với timeout
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: SCAN_TIMEOUT_SECONDS),
        continuousUpdates: true, // Cho phép update tín hiệu từ cùng device
      );

      print("✓ Đã bắt đầu quét");
    } catch (e) {
      print("✗ Lỗi khi bắt đầu quét: $e");
      rethrow;
    }
  }

  /// Dừng quét thiết bị BLE
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      print("✓ Đã dừng quét");
    } catch (e) {
      print("✗ Lỗi khi dừng quét: $e");
      rethrow;
    }
  }

  // ===== Connection Methods =====

  /// Kết nối đến một thiết bị
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("🔗 Đang kết nối tới: ${device.platformName}");

      // Kết nối với timeout
      await device.connect(
        license: License.nonprofit,
        timeout: Duration(seconds: DEVICE_CONNECT_TIMEOUT_SECONDS),
        mtu: null,
      );

      _connectedDevice = device;
      print("✓ Kết nối thành công");

      // Sau khi kết nối, tự động khám phá services
      await discoverServices();
    } catch (e) {
      print("✗ Lỗi khi kết nối: $e");
      rethrow;
    }
  }

  /// Ngắt kết nối khỏi thiết bị
  Future<void> disconnectDevice() async {
    try {
      if (_connectedDevice != null) {
        print("🔌 Đang ngắt kết nối...");
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _discoveredServices = null;
        print("✓ Đã ngắt kết nối");
      }
    } catch (e) {
      print("✗ Lỗi khi ngắt kết nối: $e");
      rethrow;
    }
  }

  // ===== Service Discovery Methods =====

  /// Khám phá các services và characteristics của thiết bị
  Future<void> discoverServices() async {
    try {
      if (_connectedDevice == null) {
        throw Exception("Không có thiết bị nào đang kết nối");
      }

      print("🔎 Đang khám phá services...");

      // Lấy danh sách services
      List<BluetoothService> services =
          await _connectedDevice!.discoverServices();

      _discoveredServices = services;

      print(
          "✓ Tìm thấy ${services.length} services:");

      // In ra thông tin services
      for (var service in services) {
        print("  📋 Service: ${service.uuid}");
        print("     Tìm thấy ${service.characteristics.length} characteristics:");

        for (var characteristic in service.characteristics) {
          print("     • ${characteristic.uuid}");
          print(
              "       Properties: ${characteristic.properties}");
        }
      }
    } catch (e) {
      print("✗ Lỗi khi khám phá services: $e");
      rethrow;
    }
  }

  /// Lấy danh sách services đã khám phá
  List<BluetoothService>? getDiscoveredServices() {
    return _discoveredServices;
  }

  /// Lấy một characteristic theo service UUID và characteristic UUID
  BluetoothCharacteristic? getCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) {
    if (_discoveredServices == null) return null;

    try {
      // Chuyển đổi UUIDs sang full format nếu cần
      String fullServiceUuid = getFullUuid(serviceUuid);
      String fullCharacteristicUuid = getFullUuid(characteristicUuid);

      // Tìm service
      var service = _discoveredServices!.firstWhere(
        (s) => _uuidMatches(s.uuid.toString(), fullServiceUuid),
      );

      // Tìm characteristic trong service
      var characteristic = service.characteristics.firstWhere(
        (c) => _uuidMatches(c.uuid.toString(), fullCharacteristicUuid),
      );

      return characteristic;
    } catch (e) {
      print(
          "✗ Không tìm thấy characteristic: serviceUuid=$serviceUuid, charUuid=$characteristicUuid");
      return null;
    }
  }

  /// Đăng ký lắng nghe (Subscribe) dữ liệu từ một characteristic
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

  Future<Stream<List<int>>?> subscribeToCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    try {
      var characteristic =
          getCharacteristic(serviceUuid, characteristicUuid);

      if (characteristic == null) {
        throw Exception(
            "Không tìm thấy characteristic: $characteristicUuid");
      }

      // Kiểm tra xem characteristic có hỗ trợ notify không
      if (!characteristic.properties.notify &&
          !characteristic.properties.indicate) {
        throw Exception(
            "Characteristic không hỗ trợ notify/indicate");
      }

      print(
          "📡 Đang đăng ký lắng nghe characteristic: $characteristicUuid");

      // Bật notify (lắng nghe)
      await characteristic.setNotifyValue(true);

      // Trả về stream của dữ liệu
      return characteristic.lastValueStream;
    } catch (e) {
      print("✗ Lỗi khi subscribe characteristic: $e");
      rethrow;
    }
  }

  /// Dừng lắng nghe dữ liệu từ một characteristic
  Future<void> unsubscribeFromCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    try {
      var characteristic =
          getCharacteristic(serviceUuid, characteristicUuid);

      if (characteristic != null) {
        await characteristic.setNotifyValue(false);
        print(
            "✓ Đã dừng lắng nghe characteristic: $characteristicUuid");
      }
    } catch (e) {
      print("✗ Lỗi khi unsubscribe characteristic: $e");
      rethrow;
    }
  }

  /// Đọc giá trị hiện tại của một characteristic
  Future<List<int>?> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    try {
      var characteristic =
          getCharacteristic(serviceUuid, characteristicUuid);

      if (characteristic == null) {
        throw Exception(
            "Không tìm thấy characteristic: $characteristicUuid");
      }

      if (!characteristic.properties.read) {
        throw Exception(
            "Characteristic không hỗ trợ read");
      }

      print(
          "📖 Đang đọc characteristic: $characteristicUuid");
      var value = await characteristic.read();

      print(
          "✓ Giá trị đọc được: $value");
      return value;
    } catch (e) {
      print("✗ Lỗi khi đọc characteristic: $e");
      rethrow;
    }
  }

  /// Ghi giá trị cho một characteristic
  Future<void> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    List<int> value,
  ) async {
    try {
      var characteristic =
          getCharacteristic(serviceUuid, characteristicUuid);

      if (characteristic == null) {
        throw Exception(
            "Không tìm thấy characteristic: $characteristicUuid");
      }

      if (!characteristic.properties.write &&
          !characteristic.properties.writeWithoutResponse) {
        throw Exception(
            "Characteristic không hỗ trợ write");
      }

      print(
          "✍️ Đang ghi giá trị: $value tới characteristic: $characteristicUuid");
      await characteristic.write(value);

      print("✓ Ghi thành công");
    } catch (e) {
      print("✗ Lỗi khi ghi characteristic: $e");
      rethrow;
    }
  }

  // ===== Helper Methods =====

  /// Kiểm tra xem có thiết bị nào đang kết nối không
  bool isConnected() {
    return _connectedDevice != null;
  }

  /// Lấy thiết bị hiện tại đang kết nối
  BluetoothDevice? getConnectedDevice() {
    return _connectedDevice;
  }
}
