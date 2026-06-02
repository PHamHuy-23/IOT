# 🏥 Ứng dụng Giám Sát Sức Khỏe BLE - Hướng Dẫn Sử Dụng

## 📋 Mục Lục
1. [Cấu Trúc Dự Án](#cấu-trúc-dự-án)
2. [Cài Đặt Dependencies](#cài-đặt-dependencies)
3. [Chạy Ứng Dụng](#chạy-ứng-dụng)
4. [Giải Thích Code](#giải-thích-code)
5. [Tùy Chỉnh UUID Cho Thiết Bị](#tùy-chỉnh-uuid)
6. [Xử Lý Lỗi Phổ Biến](#xử-lý-lỗi-phổ-biến)

---

## 🗂️ Cấu Trúc Dự Án

```
lib/
├── main.dart                          # Entry point của app
├── constants/
│   └── ble_constants.dart            # UUID và hằng số BLE
├── models/
│   └── ble_device_model.dart         # Model cho device và health data
├── screens/
│   ├── scan_screen.dart              # Màn hình quét thiết bị
│   └── connect_screen.dart           # Màn hình hiển thị dữ liệu real-time
└── services/
    ├── permission_service.dart       # Quản lý quyền truy cập
    └── ble_service.dart              # Xử lý tất cả BLE operations
```

---

## 🚀 Cài Đặt Dependencies

### Bước 1: Cập nhật pubspec.yaml
```bash
flutter pub get
```

### Bước 2: Android - Cấu hình AndroidManifest.xml
✅ Đã thêm các permissions:
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_CONNECT`
- `BLUETOOTH_SCAN`
- `ACCESS_FINE_LOCATION`

### Bước 3: iOS - Cấu hình Info.plist
✅ Đã thêm các descriptions:
- `NSBluetoothPeripheralUsageDescription`
- `NSBluetoothCentralUsageDescription`
- `NSLocationWhenInUseUsageDescription`

### Bước 4: Android Build (minSdk)
✅ Đã cập nhật minSdk = 21 (yêu cầu của BLE)

---

## ▶️ Chạy Ứng Dụng

### Android
```bash
flutter run
```

### iOS
```bash
flutter run -d <device_name>
# Hoặc
open ios/Runner.xcworkspace/  # Mở Xcode và build từ đó
```

---

## 📖 Giải Thích Code

### 1️⃣ **PHẦN 1: QUYỀN TRUY CẬP**

#### `lib/services/permission_service.dart`
- **requestBluetoothPermissions()**: Xin tất cả quyền cần thiết từ người dùng
- **hasBluetoothPermission()**: Kiểm tra xem tất cả quyền đã được cấp hay chưa
- **openAppSettings()**: Mở cài đặt ứng dụng để người dùng cấp quyền thủ công

**Ví dụ sử dụng:**
```dart
// Trong initState của ScanScreen
bool hasPermission = await PermissionService.hasBluetoothPermission();
if (!hasPermission) {
  bool granted = await PermissionService.requestBluetoothPermissions();
  // Xử lý kết quả
}
```

---

### 2️⃣ **PHẦN 2: GIAO DIỆN & LOGIC QUÉT**

#### `lib/screens/scan_screen.dart`
**Các chức năng chính:**
- ✅ Hiển thị nút "Bắt Đầu Quét" / "Dừng Quét"
- ✅ Danh sách các thiết bị phát hiện (Tên + MAC + Tín hiệu)
- ✅ Nút "Kết Nối" cho mỗi thiết bị
- ✅ Xóa tự động danh sách khi quét lại

**Quy trình:**
1. Người dùng bấm "Bắt Đầu Quét"
2. App quét BLE trong 15 giây (SCAN_TIMEOUT_SECONDS)
3. Hiển thị các thiết bị trong danh sách
4. Người dùng bấm "Kết Nối" để kết nối một thiết bị

---

### 3️⃣ **PHẦN 3: KẾT NỐI & KHÁM PHÁ DỊCH VỤ**

#### `lib/services/ble_service.dart`
**Các method chính:**
- `startScan()`: Bắt đầu quét
- `stopScan()`: Dừng quét
- `connectToDevice()`: Kết nối đến thiết bị
- `disconnectDevice()`: Ngắt kết nối
- `discoverServices()`: Khám phá các services và characteristics
- `subscribeToCharacteristic()`: Đăng ký lắng nghe dữ liệu
- `readCharacteristic()`: Đọc giá trị characteristic
- `writeCharacteristic()`: Ghi giá trị characteristic

**Ví dụ kết nối:**
```dart
try {
  await bleService.connectToDevice(device);
  await bleService.discoverServices(); // Tự động gọi trong connectToDevice
} catch (e) {
  print("Lỗi: $e");
}
```

**In ra Services (dùng để debug):**
```
✓ Tìm thấy 3 services:
  📋 Service: 180D (Heart Rate Service)
     Tìm thấy 1 characteristics:
     • 2A37 (Heart Rate Measurement)
       Properties: read, notify
```

---

### 4️⃣ **PHẦN 4: LẮNG NGHE DỮ LIỆU**

#### `lib/screens/connect_screen.dart`
**Quy trình lắng nghe dữ liệu:**

1. **_startListeningToData()**: Bắt đầu subscribe
   ```dart
   Stream<List<int>>? stream = await bleService.subscribeToCharacteristic(
     HEART_RATE_SERVICE_UUID,
     HEART_RATE_MEASUREMENT_UUID
   );
   ```

2. **_processHeartRateData()**: Xử lý dữ liệu nhịp tim
   ```dart
   // Dữ liệu nhận về là List<int>
   // Byte đầu tiên = nhịp tim (0-255 bpm)
   int heartRate = data[0];
   ```

3. **_processSpO2Data()**: Xử lý dữ liệu SpO2
   ```dart
   // Byte đầu tiên = SpO2 (0-100%)
   int spo2 = data[0];
   ```

4. **Hiển thị real-time**: UI cập nhật mỗi khi nhận dữ liệu mới

---

## 🔧 Tùy Chỉnh UUID Cho Thiết Bị

### Bước 1: Xác Định UUID Thiết Bị

Sử dụng ứng dụng BLE Scanner (Play Store/App Store) để quét thiết bị và xem UUID.

**Thông thường:**
- **Service UUID**: 180D (Heart Rate) hoặc custom (FFF0, etc.)
- **Characteristic UUID**: 2A37 (HR Measurement) hoặc custom (FFF1, etc.)

### Bước 2: Cập Nhật `lib/constants/ble_constants.dart`

**Nếu thiết bị dùng UUID chuẩn (180D, 2A37):**
- Code đã hỗ trợ sẵn ✅

**Nếu thiết bị dùng UUID custom:**
```dart
// Thêm vào file constants
const String CUSTOM_HEART_RATE_UUID = "0000FFF1-0000-1000-8000-00805f9b34fb";
const String CUSTOM_SPO2_UUID = "0000FFF2-0000-1000-8000-00805f9b34fb";
const String CUSTOM_HEALTH_SERVICE_UUID = "0000FFF0-0000-1000-8000-00805f9b34fb";
```

### Bước 3: Cập Nhật `lib/screens/connect_screen.dart`

```dart
// Trong _subscribeToHeartRate()
var stream = await widget.bleService.subscribeToCharacteristic(
  CUSTOM_HEALTH_SERVICE_UUID,  // Service UUID
  CUSTOM_HEART_RATE_UUID,      // Characteristic UUID
);
```

---

## 🛠️ Tùy Chỉnh Xử Lý Dữ Liệu

Nếu định dạng dữ liệu khác, hãy sửa trong `connect_screen.dart`:

### Ví dụ 1: Dữ liệu 2 byte

```dart
// Nếu HR là 2 bytes: [low_byte, high_byte]
void _processHeartRateData(List<int> data) {
  if (data.length < 2) return;
  
  // Combine 2 bytes
  int heartRate = (data[1] << 8) | data[0];
  
  setState(() {
    heartRate = heartRate;
  });
}
```

### Ví dụ 2: Dữ liệu từ nhiều characteristics

```dart
// Nếu HR từ characteristic 1 và SpO2 từ characteristic 2
// Chỉ cần subscribe riêng vào mỗi cái và xử lý
_subscribeToHeartRate();   // HR
_subscribeToSpO2();        // SpO2
```

---

## ❌ Xử Lý Lỗi Phổ Biến

### 1. "Quyền bị từ chối"
**Giải pháp:**
- Mở Cài đặt > Ứng dụng > [Tên App] > Quyền
- Bật Bluetooth, Vị trí, Kết nối BLE

### 2. "Không tìm thấy characteristic"
**Giải pháp:**
- Kiểm tra UUID trong constants có đúng không
- Dùng BLE Scanner xác nhận lại UUID thiết bị
- Xem log console để tìm UUID đúng

```dart
// Debug: In ra tất cả services
List<BluetoothService>? services = bleService.getDiscoveredServices();
for (var service in services!) {
  print("Service: ${service.uuid}");
  for (var char in service.characteristics) {
    print("  - ${char.uuid}");
  }
}
```

### 3. "Không nhận dữ liệu"
**Giải pháp:**
- Kiểm tra characteristic có hỗ trợ `notify` không
- Lại từ đầu xem log console

```dart
// Debug: Kiểm tra properties
var char = bleService.getCharacteristic(serviceUUID, charUUID);
print("Notify: ${char?.properties.notify}");
print("Indicate: ${char?.properties.indicate}");
```

### 4. "Lỗi kết nối timeout"
**Giải pháp:**
- Thiết bị quá xa, di chuyển gần hơn
- Tăng timeout trong BleService:
  ```dart
  const int DEVICE_CONNECT_TIMEOUT_SECONDS = 15; // Tăng từ 10 lên 15
  ```

---

## 📱 Test Trên Thiết Bị Thực

### Android
1. Bật BLE + Location
2. Cấp quyền cho app
3. Chạy: `flutter run -d <device_name>`

### iOS
1. Bật Bluetooth
2. Cấp quyền cho app (lần đầu tiên)
3. Mở file project: `open ios/Runner.xcworkspace/`
4. Build từ Xcode

---

## 🎯 Các Bước Tiếp Theo

1. **Tối ưu UI**: Thêm chart để hiển thị lịch sử dữ liệu
2. **Lưu dữ liệu**: Thêm SQLite hoặc Hive để lưu lịch sử
3. **Cảnh báo**: Thêm notification khi HR/SpO2 bất thường
4. **Multi-device**: Kết nối đến nhiều thiết bị cùng lúc
5. **Bluetooth Audio**: Thêm device audio (tai nghe)

---

## 📞 Hỗ Trợ

- **Flutter Docs**: https://flutter.dev/docs
- **flutter_blue_plus**: https://pub.dev/packages/flutter_blue_plus
- **permission_handler**: https://pub.dev/packages/permission_handler

---

**Chúc bạn thành công! 🎉**
