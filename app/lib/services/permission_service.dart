import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool get isAndroid => Platform.isAndroid;

  static Future<bool> isLocationServiceEnabled() async {
    if (!isAndroid) return true;
    final status = await Permission.location.serviceStatus;
    return status == ServiceStatus.enabled;
  }

  static Future<String?> androidBleReadinessIssue() async {
    if (!isAndroid) return null;

    if (!await hasBluetoothPermissions()) {
      return 'Cấp quyền Bluetooth và Vị trí cho app trong Cài đặt.';
    }
    if (!await isLocationServiceEnabled()) {
      return 'Bật Vị trí (GPS) trong Cài đặt Android — cần để quét BLE.';
    }
    return null;
  }

  static Future<bool> requestBluetoothPermissions() async {
    try {
      print('📋 Requesting BLE permissions...');

      final permissions = <Permission>[
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ];

      // Thêm Bluetooth cho Android < 12
      if (Platform.isAndroid) {
        permissions.add(Permission.bluetooth);
      }

      final statuses = await permissions.request();

      final bleConnectGranted = await Permission.bluetoothConnect.isGranted;
      final bleScanGranted = await Permission.bluetoothScan.isGranted;
      final locationGranted = await Permission.location.isGranted;

      final allCriticalGranted = bleConnectGranted && bleScanGranted && locationGranted;

      if (allCriticalGranted) {
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
      final bleConnectGranted = await Permission.bluetoothConnect.isGranted;
      final bleScanGranted = await Permission.bluetoothScan.isGranted;
      final locationGranted = await Permission.location.isGranted;

      // Tất cả 3 quyền này bắt buộc để quét BLE trên Android 12+
      return bleConnectGranted && bleScanGranted && locationGranted;
    } catch (e) {
      print('✗ Permission check error: $e');
      return false;
    }
  }

  static Future<bool> canRequestLocationService() async {
    if (!isAndroid) return false;
    final status = await Permission.location.serviceStatus;
    return status == ServiceStatus.disabled;
  }

  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}

