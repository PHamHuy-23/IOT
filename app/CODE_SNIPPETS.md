# 💻 ĐỀ CƯỡNG CODE - CÁC VÍ DỤ THƯỜNG DÙNG

## 🎯 Copy & Paste - Sẵn Sàng Sử Dụng

---

## 1️⃣ XIN QUYỀN

### Cách đơn giản nhất
```dart
import 'package:app/services/permission_service.dart';

// Trong initState
void initState() {
  super.initState();
  _checkPermissions();
}

void _checkPermissions() async {
  bool hasPermission = 
    await PermissionService.hasBluetoothPermission();
  
  if (!hasPermission) {
    bool granted = 
      await PermissionService.requestBluetoothPermissions();
    if (granted) {
      print("✓ Quyền được cấp");
    } else {
      print("✗ Quyền bị từ chối");
    }
  }
}
```

---

## 2️⃣ QUÉT THIẾT BỊ

### Bắt đầu quét
```dart
import 'package:app/services/ble_service.dart';

final BleService bleService = BleService();

void startScanning() async {
  try {
    await bleService.startScan();
    
    // Lắng nghe kết quả quét
    bleService.scanResults.listen((results) {
      for (var result in results) {
        print("Device: ${result.device.localName}");
        print("RSSI: ${result.rssi}");
      }
    });
  } catch (e) {
    print("Lỗi: $e");
  }
}

void stopScanning() async {
  await bleService.stopScan();
}
```

### Hiển thị danh sách (Đơn giản)
```dart
ListView.builder(
  itemCount: discoveredDevices.length,
  itemBuilder: (context, index) {
    var device = discoveredDevices[index];
    return ListTile(
      title: Text(device.deviceName),
      subtitle: Text("ID: ${device.deviceId}"),
      trailing: ElevatedButton(
        onPressed: () => connectDevice(device),
        child: Text("Connect"),
      ),
    );
  },
)
```

---

## 3️⃣ KẾT NỐI DEVICE

### Kết nối
```dart
void connectToDevice(BleDeviceModel device) async {
  try {
    // Kết nối
    await bleService.connectToDevice(device.device);
    
    // Khám phá services (tự động trong connectToDevice)
    // Nhưng có thể gọi lại nếu cần
    await bleService.discoverServices();
    
    print("✓ Kết nối thành công!");
    
    // Bây giờ có thể subscribe vào characteristics
  } catch (e) {
    print("✗ Lỗi kết nối: $e");
  }
}
```

### Ngắt kết nối
```dart
void disconnectDevice() async {
  try {
    await bleService.disconnectDevice();
    print("✓ Đã ngắt kết nối");
    Navigator.pop(context);  // Quay lại screen trước
  } catch (e) {
    print("✗ Lỗi: $e");
  }
}
```

---

## 4️⃣ KHÁM PHÁ SERVICES

### In ra tất cả services & characteristics
```dart
void printAllServices() {
  var services = bleService.getDiscoveredServices();
  
  if (services == null) {
    print("Chưa khám phá services");
    return;
  }
  
  for (var service in services) {
    print("\n📋 Service: ${service.uuid}");
    
    for (var characteristic in service.characteristics) {
      print("  ├─ UUID: ${characteristic.uuid}");
      print("  ├─ Read: ${characteristic.properties.read}");
      print("  ├─ Write: ${characteristic.properties.write}");
      print("  ├─ Notify: ${characteristic.properties.notify}");
      print("  └─ Indicate: ${characteristic.properties.indicate}");
    }
  }
}
```

### Tìm một characteristic cụ thể
```dart
var heartRateChar = bleService.getCharacteristic(
  "180D",      // Service UUID
  "2A37"       // Characteristic UUID
);

if (heartRateChar == null) {
  print("Không tìm thấy characteristic");
} else {
  print("✓ Tìm thấy Heart Rate characteristic");
}
```

---

## 5️⃣ SUBSCRIBE & LISTEN DỮ LIỆU

### Subscribe lắng nghe
```dart
void subscribeHeartRate() async {
  try {
    var stream = await bleService.subscribeToCharacteristic(
      "180D",      // Heart Rate Service UUID
      "2A37"       // Heart Rate Measurement UUID
    );
    
    if (stream != null) {
      stream.listen(
        (value) {
          // Nhận dữ liệu
          print("Dữ liệu: $value");
          
          // Parse dữ liệu
          int heartRate = value[0];
          print("❤️ Heart Rate: $heartRate bpm");
          
          // Cập nhật UI
          setState(() {
            this.heartRate = heartRate;
          });
        },
        onError: (error) {
          print("Lỗi subscribe: $error");
        },
        cancelOnError: false,
      );
    }
  } catch (e) {
    print("Lỗi: $e");
  }
}
```

### Unsubscribe (Dừng lắng nghe)
```dart
void unsubscribeHeartRate() async {
  await bleService.unsubscribeFromCharacteristic(
    "180D",
    "2A37"
  );
  print("✓ Đã dừng lắng nghe");
}
```

---

## 6️⃣ ĐỌC & GHI DỮ LIỆU

### Đọc giá trị một lần
```dart
void readBattery() async {
  try {
    var value = await bleService.readCharacteristic(
      "180A",      // Device Info Service
      "2A19"       // Battery Level
    );
    
    if (value != null) {
      int battery = value[0];  // First byte = percentage
      print("🔋 Battery: $battery%");
    }
  } catch (e) {
    print("Lỗi đọc: $e");
  }
}
```

### Ghi giá trị (Control device)
```dart
void writeCommand() async {
  try {
    // Ghi 1 byte có giá trị 0x01
    await bleService.writeCharacteristic(
      "FFF0",      // Custom Service
      "FFF3",      // Custom Command Characteristic
      [0x01]       // Byte value
    );
    print("✓ Đã ghi giá trị");
  } catch (e) {
    print("Lỗi ghi: $e");
  }
}

void writeMultipleBytes() async {
  try {
    // Ghi nhiều bytes
    List<int> data = [0xAA, 0xBB, 0xCC, 0xDD];
    
    await bleService.writeCharacteristic(
      "FFF0",
      "FFF3",
      data
    );
    print("✓ Đã ghi ${data.length} bytes");
  } catch (e) {
    print("Lỗi: $e");
  }
}
```

---

## 7️⃣ XỬ LÝ DỮ LIỆU

### Parse byte đơn giản
```dart
void parseSimple(List<int> data) {
  // 1 byte = 1 giá trị
  if (data.isEmpty) return;
  
  int value = data[0];  // 0-255
  print("Giá trị: $value");
}
```

### Parse 2 bytes (Big-endian)
```dart
void parse2BytesBigEndian(List<int> data) {
  if (data.length < 2) return;
  
  // MSB (Most Significant Byte) đứng trước
  int value = (data[0] << 8) | data[1];
  print("Giá trị 16-bit: $value");
}
```

### Parse 2 bytes (Little-endian)
```dart
void parse2BytesLittleEndian(List<int> data) {
  if (data.length < 2) return;
  
  // LSB (Least Significant Byte) đứng trước
  int value = (data[1] << 8) | data[0];
  print("Giá trị 16-bit: $value");
}
```

### Parse với flags
```dart
void parseWithFlags(List<int> data) {
  if (data.isEmpty) return;
  
  // Byte 0 = Flags
  int flags = data[0];
  
  // Bit 0 chỉ định format (0 = uint8, 1 = uint16)
  bool isUint16 = (flags & 0x01) != 0;
  
  int heartRate;
  if (isUint16) {
    // Format uint16, 2 bytes từ index 1-2
    if (data.length < 3) return;
    heartRate = (data[1] << 8) | data[2];
  } else {
    // Format uint8, 1 byte từ index 1
    if (data.length < 2) return;
    heartRate = data[1];
  }
  
  print("❤️ HR: $heartRate bpm");
}
```

### Convert byte array thành string
```dart
void parseString(List<int> data) {
  // Chuyển byte array thành string
  String text = String.fromCharCodes(data);
  print("Text: $text");
  
  // Ví dụ: [72, 101, 108, 108, 111] = "Hello"
}
```

---

## 8️⃣ VALIDATION DỮ LIỆU

### Validate Heart Rate
```dart
bool isValidHeartRate(int hr) {
  return hr >= 30 && hr <= 220;
}

void processHeartRate(int hr) {
  if (!isValidHeartRate(hr)) {
    print("⚠️ HR không hợp lệ: $hr");
    return;
  }
  
  print("✓ HR hợp lệ: $hr");
  setState(() {
    heartRate = hr;
  });
}
```

### Validate SpO2
```dart
bool isValidSpO2(int spo2) {
  return spo2 >= 0 && spo2 <= 100;
}

void processSpO2(int spo2) {
  if (!isValidSpO2(spo2)) {
    print("⚠️ SpO2 không hợp lệ: $spo2");
    return;
  }
  
  if (spo2 < 95) {
    print("⚠️ SpO2 thấp!");
  }
  
  setState(() {
    this.spo2 = spo2;
  });
}
```

---

## 9️⃣ UI DISPLAY

### Hiển thị Heart Rate Card
```dart
Card(
  color: Colors.red[50],
  child: Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(Icons.favorite, size: 48, color: Colors.red),
        SizedBox(height: 12),
        Text(
          "Nhịp Tim",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$heartRate",
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Text(
              "bpm",
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          _getHeartRateStatus(heartRate),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: heartRate < 60 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    ),
  ),
)
```

### Status Badge
```dart
Widget statusBadge(bool isConnected) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isConnected ? Colors.green : Colors.red,
        ),
      ),
      SizedBox(width: 8),
      Text(isConnected ? "Đã Kết Nối" : "Mất Kết Nối"),
    ],
  );
}
```

---

## 🔟 LƯỚI TÓM TẮT

| Tác Vụ | Method | File |
|--------|--------|------|
| Xin Quyền | `PermissionService.requestBluetoothPermissions()` | permission_service.dart |
| Quét | `bleService.startScan()` | ble_service.dart |
| Dừng Quét | `bleService.stopScan()` | ble_service.dart |
| Kết Nối | `bleService.connectToDevice()` | ble_service.dart |
| Khám Phá | `bleService.discoverServices()` | ble_service.dart |
| Subscribe | `bleService.subscribeToCharacteristic()` | ble_service.dart |
| Đọc | `bleService.readCharacteristic()` | ble_service.dart |
| Ghi | `bleService.writeCharacteristic()` | ble_service.dart |

---

**Sử dụng các snippets này để nhanh chóng build features! 🚀**
