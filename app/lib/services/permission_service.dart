import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBluetoothPermissions() async {
    try {
      print('📋 Requesting BLE permissions...');

      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final allGranted = statuses.values.every(
        (status) => status.isGranted,
      );

      if (allGranted) {
        print('✓ All BLE permissions granted');
        return true;
      } else {
        print('✗ Some permissions denied:');
        statuses.forEach((permission, status) {
          print('  - $permission: $status');
        });
        return false;
      }
    } catch (e) {
      print('✗ Permission request error: $e');
      return false;
    }
  }

  static Future<bool> hasBluetoothPermissions() async {
    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      print('✗ Permission check error: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

