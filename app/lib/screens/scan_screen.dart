import 'package:flutter/material.dart';
import '../constants/ble_constants.dart';
import '../models/ble_device_model.dart';
import '../services/permission_service.dart';
import '../services/ble_service.dart';
import 'connect_screen.dart';

/// Màn hình quét và hiển thị danh sách thiết bị BLE
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final BleService _bleService = BleService();
  List<BleDeviceModel> discoveredDevices = [];
  bool isScanning = false;
  String statusMessage = "Nhấn nút để bắt đầu quét";

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  /// Kiểm tra và xin quyền khi vừa mở app
  void _checkAndRequestPermissions() async {
    bool hasPermission = await PermissionService.hasBluetoothPermission();
    if (!hasPermission) {
      bool granted = await PermissionService.requestBluetoothPermissions();
      if (granted) {
        setState(() {
          statusMessage = "Quyền đã được cấp. Sẵn sàng quét.";
        });
      } else {
        setState(() {
          statusMessage = "Quyền bị từ chối. Vui lòng cấp quyền trong cài đặt.";
        });
      }
    }
  }

  /// Bắt đầu quét thiết bị BLE
  void _startScan() async {
    // Xóa danh sách thiết bị cũ
    discoveredDevices.clear();

    setState(() {
      isScanning = true;
      statusMessage = "Đang quét thiết bị...";
    });

    try {
      // Bắt đầu quét
      await _bleService.startScan();

      // Lắng nghe sự kiện phát hiện thiết bị
      _bleService.scanResults.listen((results) {
        List<BleDeviceModel> newDevices = [];

        for (var result in results) {
          // Tạo BleDeviceModel từ kết quả quét
          BleDeviceModel device = BleDeviceModel(
            device: result.device,
            deviceName: result.device.platformName.isEmpty
                ? result.device.remoteId.str
                : result.device.platformName,
            deviceId: result.device.remoteId.str,
            rssi: result.rssi,
          );

          // Kiểm tra xem thiết bị đã tồn tại trong danh sách chưa
          bool exists = newDevices
              .any((d) => d.deviceId == device.deviceId);
          if (!exists) {
            newDevices.add(device);
          }
        }

        setState(() {
          // Cập nhật danh sách, loại bỏ duplicates
          for (var newDevice in newDevices) {
            bool alreadyExists = discoveredDevices
                .any((d) => d.deviceId == newDevice.deviceId);
            if (!alreadyExists) {
              discoveredDevices.add(newDevice);
            }
          }

          statusMessage =
              "Tìm thấy ${discoveredDevices.length} thiết bị";
        });
      });

      // Tự động dừng quét sau SCAN_TIMEOUT_SECONDS giây
      await Future.delayed(
          Duration(seconds: SCAN_TIMEOUT_SECONDS));

      _stopScan();
    } catch (e) {
      setState(() {
        statusMessage = "Lỗi khi quét: $e";
        isScanning = false;
      });
    }
  }

  /// Dừng quét thiết bị
  Future<void> _stopScan() async {
    try {
      await _bleService.stopScan();
      setState(() {
        isScanning = false;
        if (discoveredDevices.isEmpty) {
          statusMessage = "Quét xong. Không tìm thấy thiết bị.";
        } else {
          statusMessage =
              "Quét xong. Tìm thấy ${discoveredDevices.length} thiết bị.";
        }
      });
    } catch (e) {
      setState(() {
        statusMessage = "Lỗi khi dừng quét: $e";
      });
    }
  }

  /// Kết nối đến một thiết bị
  void _connectToDevice(BleDeviceModel device) async {
    setState(() {
      device.isConnecting = true;
    });

    try {
      // Kết nối đến thiết bị
      await _bleService.connectToDevice(device.device);

      // Cập nhật trạng thái
      setState(() {
        device.updateConnectionStatus(true);
      });

      // Dừng quét vì đã kết nối thành công
      await _stopScan();

      // Điều hướng sang màn hình kết nối
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConnectScreen(
              device: device,
              bleService: _bleService,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        device.isConnecting = false;
        statusMessage = "Lỗi kết nối: $e";
      });

      // Hiển thị dialog lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Không thể kết nối: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét Thiết bị BLE"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // ===== Phần Status =====
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Nút Bắt đầu/Dừng quét
                ElevatedButton.icon(
                  onPressed: isScanning ? _stopScan : _startScan,
                  icon: Icon(
                    isScanning ? Icons.stop : Icons.bluetooth_searching,
                  ),
                  label: Text(
                    isScanning ? "Dừng Quét" : "Bắt Đầu Quét",
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isScanning ? Colors.red : Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== Phần Danh Sách Thiết bị =====
          Expanded(
            child: discoveredDevices.isEmpty
                ? Center(
                    child: Text(
                      isScanning
                          ? "Đang quét thiết bị...\n\nVui lòng chờ..."
                          : "Nhấn 'Bắt Đầu Quét' để tìm thiết bị",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: discoveredDevices.length,
                    itemBuilder: (context, index) {
                      BleDeviceModel device = discoveredDevices[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: ListTile(
                          // Biểu tượng thiết bị
                          leading: Icon(
                            device.isConnected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth,
                            color: device.isConnected
                                ? Colors.green
                                : Colors.blue,
                            size: 28,
                          ),

                          // Tên thiết bị
                          title: Text(
                            device.getDisplayName(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          // MAC Address & Tín hiệu
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "ID: ${device.deviceId}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Tín hiệu: ${device.rssi} dBm (${device.getSignalStrength()})",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          // Nút Kết nối
                          trailing: device.isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: device.isConnected
                                      ? null
                                      : () => _connectToDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: device.isConnected
                                        ? Colors.green
                                        : Colors.blue,
                                    disabledBackgroundColor: Colors.green,
                                  ),
                                  child: Text(
                                    device.isConnected
                                        ? "Đã Kết Nối"
                                        : "Kết Nối",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dừng quét khi thoát màn hình
    _bleService.stopScan();
    super.dispose();
  }
}
