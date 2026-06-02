import 'package:permission_handler/permission_handler.dart';

/// Service quản lý các quyền truy cập cần thiết cho BLE
class PermissionService {
  // Kiểm tra và xin quyền cho BLE
  static Future<bool> requestBluetoothPermissions() async {
    try {
      // Danh sách quyền cần xin
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      // Kiểm tra xem tất cả quyền đã được cấp chưa
      bool allGranted = statuses.values.every(
        (status) => status.isDenied == false,
      );

      if (allGranted) {
        print('✓ Đã cấp tất cả quyền BLE');
        return true;
      } else {
        print('✗ Một số quyền bị từ chối');
        return false;
      }
    } catch (e) {
      print('Lỗi khi xin quyền: $e');
      return false;
    }
  }

  // Kiểm tra xem quyền BLE có được cấp hay không
  static Future<bool> hasBluetoothPermission() async {
    PermissionStatus bluetoothStatus = await Permission.bluetooth.status;
    PermissionStatus bluetoothConnectStatus =
        await Permission.bluetoothConnect.status;
    PermissionStatus bluetoothScanStatus =
        await Permission.bluetoothScan.status;
    PermissionStatus locationStatus = await Permission.location.status;

    return bluetoothStatus.isGranted &&
        bluetoothConnectStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        locationStatus.isGranted;
  }

  // Mở cài đặt ứng dụng để người dùng cấp quyền thủ công
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
