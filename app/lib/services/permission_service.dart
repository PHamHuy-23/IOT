import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool get isAndroid => Platform.isAndroid;

  /// Many Android phones block BLE scan unless system Location (GPS) is ON.
  static Future<bool> isLocationServiceEnabled() async {
    if (!isAndroid) {
      return true;
    }
    final status = await Permission.location.serviceStatus;
    return status == ServiceStatus.enabled;
  }

  static Future<String?> androidBleReadinessIssue() async {
    if (!isAndroid) {
      return null;
    }
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
      const permissions = [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ];

      for (final permission in permissions) {
        if (!(await permission.status).isGranted) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('✗ Permission check error: $e');
      return false;
    }
  }

  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}

