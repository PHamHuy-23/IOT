import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Model đại diện cho một thiết bị BLE
class BleDeviceModel {
  final BluetoothDevice device;
  final String deviceName;
  final String deviceId; // MAC address hoặc UUID tùy platform
  final int rssi; // Độ mạnh tín hiệu
  bool isConnecting = false;
  bool isConnected = false;

  BleDeviceModel({
    required this.device,
    required this.deviceName,
    required this.deviceId,
    required this.rssi,
  });

  // Cập nhật trạng thái kết nối
  void updateConnectionStatus(bool connected) {
    isConnected = connected;
    isConnecting = false;
  }

  // Lấy thông tin hiển thị
  String getDisplayName() {
    return deviceName.isEmpty ? "Thiết bị không tên" : deviceName;
  }

  // Lấy thông tin tín hiệu
  String getSignalStrength() {
    if (rssi > -50) return "Rất mạnh";
    if (rssi > -70) return "Mạnh";
    if (rssi > -90) return "Trung bình";
    return "Yếu";
  }

  @override
  String toString() =>
      'BleDeviceModel(name: $deviceName, id: $deviceId, rssi: $rssi)';
}

/// Model lưu dữ liệu sức khỏe nhận được từ thiết bị
class HealthData {
  final int heartRate; // Nhịp tim (bpm)
  final int spo2; // Nồng độ oxy (%)
  final DateTime timestamp; // Thời gian nhận dữ liệu

  HealthData({
    required this.heartRate,
    required this.spo2,
    required this.timestamp,
  });

  // Kiểm tra dữ liệu có hợp lệ không
  bool isValid() {
    return heartRate >= 30 && heartRate <= 220 && spo2 >= 0 && spo2 <= 100;
  }

  @override
  String toString() =>
      'HealthData(HR: $heartRate bpm, SpO2: $spo2%, time: $timestamp)';
}
