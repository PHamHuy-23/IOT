import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants/ble_constants.dart';
import '../models/ble_device_model.dart';
import '../services/ble_service.dart';

/// Màn hình hiển thị dữ liệu real-time (Nhịp tim & SpO2)
class ConnectScreen extends StatefulWidget {
  final BleDeviceModel device;
  final BleService bleService;

  const ConnectScreen({
    super.key,
    required this.device,
    required this.bleService,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  // ===== Dữ liệu hiển thị =====
  int heartRate = 0;
  int spo2 = 0;
  DateTime? lastUpdateTime;
  bool isListening = false;
  String statusMessage = "Đang kết nối...";
  List<HealthData> dataHistory = []; // Lịch sử dữ liệu

  @override
  void initState() {
    super.initState();
    _startListeningToData();
  }

  /// Bắt đầu lắng nghe dữ liệu từ thiết bị
  void _startListeningToData() async {
    setState(() {
      statusMessage = "Đang kết nối và khám phá services...";
    });

    try {
      // Khám phá services (nếu chưa khám phá)
      if (widget.bleService.getDiscoveredServices() == null) {
        await widget.bleService.discoverServices();
      }

      // ===== CỐ GẮNG SUBSCRIBE HEART RATE =====
      _subscribeToHeartRate();

      // ===== CỐ GẮNG SUBSCRIBE SPO2 =====
      _subscribeToSpO2();

      setState(() {
        isListening = true;
        statusMessage = "Đã kết nối. Lắng nghe dữ liệu...";
      });
    } catch (e) {
      setState(() {
        statusMessage = "Lỗi: $e";
      });
      print("Lỗi: $e");
    }
  }

  /// Subscribe lắng nghe Heart Rate
  void _subscribeToHeartRate() async {
    try {
      // Thử Heart Rate Service (UUID chuẩn)
      var stream = await widget.bleService.subscribeToCharacteristic(
        HEART_RATE_SERVICE_UUID,
        HEART_RATE_MEASUREMENT_UUID,
      );

      if (stream != null) {
        print("✓ Đã subscribe Heart Rate Service");

        // Lắng nghe sự kiện từ stream
        stream.listen(
          (value) {
            // Xử lý dữ liệu nhận được
            print("RAW HR BLE: $value");
            _processHeartRateData(value);
          },
          onError: (e) {
            print("Lỗi khi nhận dữ liệu HR: $e");
          },
          cancelOnError: false,
        );
      }
    } catch (e) {
      print("Không thể subscribe Heart Rate Service: $e");

      // Thử custom UUID
      try {
        var stream = await widget.bleService.subscribeToCharacteristic(
          HEART_RATE_SERVICE_UUID,
          HEART_RATE_MEASUREMENT_UUID,
        );

        if (stream != null) {
          print("✓ Đã subscribe Custom Heart Rate UUID");

          stream.listen(
            (value) {
              print("RAW HR BLE: $value");
              _processHeartRateData(value);
            },
            onError: (e) {
              print("Lỗi khi nhận dữ liệu HR custom: $e");
            },
            cancelOnError: false,
          );
        }
      } catch (e2) {
        print("Không thể subscribe Custom Heart Rate: $e2");
      }
    }
  }

  /// Subscribe lắng nghe SpO2
  void _subscribeToSpO2() async {
    try {
      // Thử Custom SpO2 Service
      var stream = await widget.bleService.subscribeToCharacteristic(
        SPO2_SERVICE_UUID,
        SPO2_MEASUREMENT_UUID,
      );

      if (stream != null) {
        print("✓ Đã subscribe Custom SpO2 UUID");

        stream.listen(
          (value) {
            // Xử lý dữ liệu SpO2
            print("RAW SpO2 BLE: $value");
            _processSpO2Data(value);
          },
          onError: (e) {
            print("Lỗi khi nhận dữ liệu SpO2: $e");
          },
          cancelOnError: false,
        );
      }
    } catch (e) {
      print("Không thể subscribe SpO2 Service: $e");
    }
  }

  /// Xử lý dữ liệu nhịp tim (Heart Rate)
  /// Giả định: Byte đầu tiên là nhịp tim (0-255 bpm)
  void _processHeartRateData(List<int> data) {
    if (data.isEmpty) return;

    try {
      // Trích xuất nhịp tim từ byte đầu tiên
      int newHeartRate;
      if (data.length >= 2 && (data[0] & 0x01) == 0) {
        newHeartRate = data[1];
      } else if (data.length >= 3 && (data[0] & 0x01) == 1) {
        newHeartRate = data[1] | (data[2] << 8);
      } else {
        newHeartRate = data[0];
      }

      if (newHeartRate == 0) {
        setState(() {
          heartRate = 0;
          lastUpdateTime = DateTime.now();
        });
        return;
      }

      // Validate dữ liệu
      if (newHeartRate < MIN_HEART_RATE ||
          newHeartRate > MAX_HEART_RATE) {
        print(
            "⚠️ Dữ liệu HR không hợp lệ: $newHeartRate bpm");
        return;
      }

      setState(() {
        heartRate = newHeartRate;
        lastUpdateTime = DateTime.now();
      });

      print("❤️ Heart Rate: $newHeartRate bpm");

      // Cập nhật lịch sử nếu cả HR và SpO2 đã có dữ liệu
      if (heartRate > 0 && spo2 > 0) {
        _addToHistory();
      }
    } catch (e) {
      print("Lỗi khi xử lý dữ liệu HR: $e");
    }
  }

  /// Xử lý dữ liệu SpO2 (Oxygen Saturation)
  /// Giả định: Byte đầu tiên là SpO2 (0-100%)
  void _processSpO2Data(List<int> data) {
    if (data.isEmpty) return;

    try {
      // Trích xuất SpO2 từ byte đầu tiên
      int newSpo2 = data[0];

      // Validate dữ liệu
      if (newSpo2 < MIN_SPO2 || newSpo2 > MAX_SPO2) {
        print(
            "⚠️ Dữ liệu SpO2 không hợp lệ: $newSpo2%");
        return;
      }

      setState(() {
        spo2 = newSpo2;
        lastUpdateTime = DateTime.now();
      });

      print("💨 SpO2: $newSpo2%");

      // Cập nhật lịch sử nếu cả HR và SpO2 đã có dữ liệu
      if (heartRate > 0 && spo2 > 0) {
        _addToHistory();
      }
    } catch (e) {
      print("Lỗi khi xử lý dữ liệu SpO2: $e");
    }
  }

  /// Thêm dữ liệu vào lịch sử
  void _addToHistory() {
    HealthData newData = HealthData(
      heartRate: heartRate,
      spo2: spo2,
      timestamp: DateTime.now(),
    );

    // Chỉ thêm vào lịch sử nếu dữ liệu hợp lệ
    if (newData.isValid()) {
      setState(() {
        dataHistory.add(newData);

        // Giữ tối đa 100 bản ghi trong lịch sử
        if (dataHistory.length > 100) {
          dataHistory.removeAt(0);
        }
      });
    }
  }

  /// Ngắt kết nối
  void _disconnect() async {
    try {
      await widget.bleService.disconnectDevice();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi ngắt kết nối: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm để bạn dễ dàng tùy chỉnh parsing dữ liệu
  /// PHẦN QUAN TRỌNG: Tùy chỉnh parsing dữ liệu tùy theo định dạng của thiết bị
  ///
  /// Ví dụ nếu dữ liệu gửi về là:
  /// [byte0, byte1, byte2, ...]
  /// Và bạn cần extract HR từ byte 1-2 và SpO2 từ byte 3
  /// Bạn có thể sửa đoạn code ở _processHeartRateData như sau:
  ///
  /// void _processHeartRateData(List<int> data) {
  ///   if (data.length < 2) return;
  ///   // Combine 2 bytes: (byte1 << 8) | byte2
  ///   int newHeartRate = (data[1] << 8) | data[2];
  ///   ...
  /// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.getDisplayName()),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // ===== Phần Status =====
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (lastUpdateTime != null)
                  Text(
                    "Cập nhật lần cuối: ${lastUpdateTime!.hour}:${lastUpdateTime!.minute}:${lastUpdateTime!.second}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),

          // ===== Phần Hiển thị dữ liệu =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nhịp tim
                  _buildHealthDataCard(
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    label: "Nhịp Tim",
                    value: heartRate.toString(),
                    unit: "bpm",
                    backgroundColor: Colors.red[50],
                    status: _getHeartRateStatus(heartRate),
                  ),

                  // SpO2
                  _buildHealthDataCard(
                    icon: Icons.air,
                    iconColor: Colors.blue,
                    label: "SpO2",
                    value: spo2.toString(),
                    unit: "%",
                    backgroundColor: Colors.blue[50],
                    status: _getSpO2Status(spo2),
                  ),
                ],
              ),
            ),
          ),

          // ===== Lịch sử dữ liệu =====
          if (dataHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lịch sử dữ liệu:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      itemCount: dataHistory.length,
                      itemBuilder: (context, index) {
                        var data = dataHistory[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                "${data.timestamp.hour}:${data.timestamp.minute}:${data.timestamp.second}",
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "HR: ${data.heartRate} | SpO2: ${data.spo2}%",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ===== Nút Ngắt kết nối =====
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.close),
              label: const Text("Ngắt Kết Nối"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị một card dữ liệu sức khỏe
  Widget _buildHealthDataCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required Color? backgroundColor,
    required String status,
  }) {
    return Card(
      color: backgroundColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lấy trạng thái nhịp tim
  String _getHeartRateStatus(int hr) {
    if (hr == 0) return "Chờ dữ liệu...";
    if (hr < 60) return "Nhịp chậm";
    if (hr <= 100) return "Bình thường";
    return "Nhịp nhanh";
  }

  /// Lấy trạng thái SpO2
  String _getSpO2Status(int spo2) {
    if (spo2 == 0) return "Chờ dữ liệu...";
    if (spo2 < 95) return "⚠️ Thấp";
    if (spo2 <= 100) return "Bình thường";
    return "Kiểm tra thiết bị";
  }

  /// Lấy màu cho trạng thái
  Color _getStatusColor(String status) {
    if (status.contains("Chờ")) return Colors.grey;
    if (status.contains("Bình thường")) return Colors.green;
    if (status.contains("⚠️")) return Colors.orange;
    return Colors.orange;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
