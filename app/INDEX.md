# 📚 ỨNG DỤNG BLE HEALTH MONITOR - HƯỚNG DẪN ĐẦY ĐỦ

## 🎯 Mục Lục Chính

Dự án này bao gồm tất cả mọi thứ bạn cần để xây dựng ứng dụng Flutter giám sát sức khỏe với BLE.

### 📖 Tài Liệu Chính

1. **[README_HUONG_DAN.md](README_HUONG_DAN.md)** ⭐ START HERE
   - Cấu trúc dự án
   - Cài đặt step-by-step
   - Giải thích từng phần code
   - Tùy chỉnh UUID cho thiết bị

2. **[TONG_HOP.md](TONG_HOP.md)**
   - Tóm tắt toàn bộ công việc đã hoàn thành
   - Danh sách file đã tạo/sửa
   - Cách sử dụng app
   - Checklist hoàn thành

3. **[LUONG_HOAT_DONG.md](LUONG_HOAT_DONG.md)**
   - Diagram luồng hoạt động
   - Flow chart từng màn hình
   - Class interaction diagram
   - Data flow visualization

4. **[CHEAT_SHEET.md](CHEAT_SHEET.md)** ⚡ THAM KHẢO NHANH
   - Lệnh thường dùng
   - Hàm thường dùng
   - UUID phổ biến
   - Quick customization
   - Debug tricks

---

## 📁 Cấu Trúc Dự Án

```
lib/
├── main.dart                         # Entry point
├── constants/
│   └── ble_constants.dart           # UUID & constants
├── models/
│   └── ble_device_model.dart        # Data models
├── screens/
│   ├── scan_screen.dart             # Quét device
│   └── connect_screen.dart          # Dữ liệu real-time
└── services/
    ├── ble_service.dart             # BLE logic
    └── permission_service.dart      # Permissions

android/
├── app/
│   └── build.gradle.kts             # ✏️ minSdk = 21
    └── src/main/
        └── AndroidManifest.xml      # ✏️ Permissions added

ios/
└── Runner/
    └── Info.plist                   # ✏️ Bluetooth descriptions

pubspec.yaml                         # ✏️ Dependencies added
```

---

## 🎓 4 Phần Chính

### PHẦN 1️⃣: CẤU HÌNH QUYỀN ✅
**File chính:** `lib/services/permission_service.dart`

- [x] Thêm dependencies: flutter_blue_plus, permission_handler
- [x] Cấu hình Android: AndroidManifest.xml + build.gradle
- [x] Cấu hình iOS: Info.plist
- [x] Service xin quyền runtime

**Bạn sẽ học:**
- Cách xin runtime permissions
- Cấu hình platform-specific manifests
- Handling permission denied cases

---

### PHẦN 2️⃣: GIAO DIỆN & LOGIC QUÉT ✅
**File chính:** `lib/screens/scan_screen.dart`

- [x] Nút "Bắt Đầu Quét" / "Dừng Quét"
- [x] ListView hiển thị thiết bị
- [x] Thông tin: Tên + ID + Tín hiệu
- [x] Nút "Kết Nối" cho mỗi device

**Bạn sẽ học:**
- Flutter UI patterns (Card, ListTile, ElevatedButton)
- Stream lắng nghe quét results
- State management với setState
- ListView.builder với dynamic data

---

### PHẦN 3️⃣: KẾT NỐI & KHÁM PHÁ ✅
**File chính:** `lib/services/ble_service.dart`

- [x] Kết nối BLE device
- [x] Khám phá services & characteristics
- [x] In ra danh sách UUID tìm thấy
- [x] Tìm kiếm characteristic theo UUID

**Bạn sẽ học:**
- BLE architecture (Services → Characteristics)
- flutter_blue_plus API
- Error handling & timeouts
- Service discovery pattern

---

### PHẦN 4️⃣: LẮNG NGHE DỮ LIỆU ✅
**File chính:** `lib/screens/connect_screen.dart`

- [x] Subscribe lắng nghe Heart Rate
- [x] Subscribe lắng nghe SpO2
- [x] Parse dữ liệu từ bytes
- [x] Hiển thị real-time UI
- [x] Lịch sử dữ liệu

**Bạn sẽ học:**
- Streams & listening in Flutter
- Data parsing từ bytes
- Real-time UI updates
- Data validation
- History management

---

## 🚀 Các Bước Để Bắt Đầu

### 1️⃣ **Cài Đặt**
```bash
# Clone hoặc vào folder
cd g:\Desktop\IOT\app

# Cài dependencies
flutter pub get
```

### 2️⃣ **Chạy App**
```bash
# Android
flutter run

# iOS - Mở Xcode
open ios/Runner.xcworkspace/
```

### 3️⃣ **Test**
- Bật Bluetooth trên điện thoại
- Cấp quyền cho app (nếu cần)
- Bấm "Bắt Đầu Quét"
- Chọn device từ danh sách
- Xem dữ liệu real-time

### 4️⃣ **Tùy Chỉnh**
- Xem `CHEAT_SHEET.md` để đổi UUID
- Sửa parse logic nếu cần
- Thêm thêm fields/features

---

## 📱 Cách Sử Dụng App

```
┌─────────────────────────────────┐
│  1. ScanScreen                  │
│  ├─ Bắt Đầu Quét               │
│  ├─ Danh sách device            │
│  └─ Chọn "Kết Nối" → Next       │
└─────────────────────────────────┘
                ↓
┌─────────────────────────────────┐
│  2. ConnectScreen               │
│  ├─ ❤️ Heart Rate (real-time)    │
│  ├─ 💨 SpO2 (real-time)          │
│  ├─ Status + History             │
│  └─ Ngắt Kết Nối → Back         │
└─────────────────────────────────┘
```

---

## 🔍 Debug / Troubleshoot

### Xem Log
```bash
flutter run -v  # Verbose mode
```

### Check Services
- Kết nối device
- Xem console output
- Services sẽ được print ra

### Kiểm Tra Quyền
- Settings > [App Name] > Permissions
- Bật Bluetooth + Location

### Kiểm Tra Device
- Dùng BLE Scanner app
- Xem UUID của device
- So sánh với code

---

## 💡 Tips

1. **Đọc từng phần tài liệu theo thứ tự:**
   - PHẦN 1 → 2 → 3 → 4
   - Mỗi phần build trên phần trước

2. **Tham khảo CHEAT_SHEET.md:**
   - Dùng khi cần tìm cách nhanh
   - Quick reference cho hàm/UUID

3. **Xem LUONG_HOAT_DONG.md:**
   - Dùng khi cần hiểu flow
   - Diagram rất helpful

4. **Test trên device thực:**
   - Emulator BLE có hạn chế
   - Real device tốt hơn nhiều

---

## 🎯 Điều Bạn Sẽ Học

✅ Cấu hình platform (Android & iOS)
✅ Runtime permissions handling
✅ BLE communication với flutter_blue_plus
✅ Service discovery & characteristics
✅ Stream listening & real-time data
✅ Data parsing từ bytes
✅ Flutter UI patterns
✅ State management
✅ Error handling
✅ Debug techniques

---

## 📦 Dependencies Được Sử Dụng

```yaml
flutter_blue_plus: ^1.37.0   # BLE communication
permission_handler: ^11.4.3  # Runtime permissions
```

---

## 🎓 Kiến Thức Yêu Cầu

**Cơ bản:** Flutter cơ bản, Dart syntax
**Mở rộng:** Streams, async/await, collections

**Không cần:** BLE expertise (hướng dẫn sẽ giải thích)

---

## 📞 FAQ

**Q: Làm sao biết UUID của device?**
A: Dùng BLE Scanner app (Play Store/App Store) để quét device

**Q: Có thể kết nối nhiều device không?**
A: Hiện tại hỗ trợ 1 device. Mở rộng trong tương lai

**Q: Dữ liệu định dạng khác sao?**
A: Sửa `_processHeartRateData()` & `_processSpO2Data()` theo format device

**Q: Chạy trên emulator được không?**
A: Tốt nhất chạy trên device thực vì BLE emulation có hạn

**Q: Lưu dữ liệu vào database?**
A: Thêm SQLite hoặc Hive. Xem phần "Tiếp Theo" trong tài liệu

---

## 🎉 Kết Luận

Đây là một ứng dụng **hoàn chỉnh** sẵn sàng để:
- ✅ Chạy ngay
- ✅ Tùy chỉnh cho device của bạn
- ✅ Mở rộng thêm features
- ✅ Học những kiến thức BLE & Flutter

**Chúc bạn thành công! 🚀**

---

**Liên Hệ:**
- Xem lại tài liệu trong project
- Check CHEAT_SHEET cho quick reference
- Xem LUONG_HOAT_DONG cho flow understanding

**Last Updated:** 2024 | Status: ✅ Complete
