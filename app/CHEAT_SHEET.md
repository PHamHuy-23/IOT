# ⚡ CHEAT SHEET - THAM KHẢO NHANH

## 🚀 Start Here

```bash
# 1. Cài dependencies
flutter pub get

# 2. Chạy app
flutter run          # Android
open ios/Runner.xcworkspace/  # iOS

# 3. Xem log
flutter run -v
```

---

## 📁 File Quan Trọng

| File | Mục Đích |
|------|---------|
| `lib/main.dart` | Entry point → ScanScreen |
| `lib/services/ble_service.dart` | Tất cả BLE logic |
| `lib/screens/scan_screen.dart` | Quét + danh sách device |
| `lib/screens/connect_screen.dart` | Dữ liệu real-time |
| `lib/constants/ble_constants.dart` | UUID + hằng số |
| `lib/services/permission_service.dart` | Xin quyền |

---

## 🔑 UUID Thường Dùng

```dart
// Chuẩn GATT
"180D"  // Heart Rate Service
"2A37"  // Heart Rate Measurement
"180A"  // Device Info Service
"2A19"  // Battery Level
"2A29"  // Manufacturer

// Custom (Tuỳ thiết bị)
"FFF0"  // Custom Service
"FFF1"  // Custom HR
"FFF2"  // Custom SpO2
```

---

## 💻 Hàm Thường Dùng

### Scan
```dart
await bleService.startScan();
await bleService.stopScan();
```

### Connect
```dart
await bleService.connectToDevice(device);
await bleService.disconnectDevice();
```

### Service Discovery
```dart
await bleService.discoverServices();
var char = bleService.getCharacteristic("180D", "2A37");
```

### Listen Data
```dart
Stream<List<int>>? stream = 
  await bleService.subscribeToCharacteristic("180D", "2A37");

stream?.listen((data) {
  print("Received: $data");
});
```

### Read/Write
```dart
List<int>? value = await bleService.readCharacteristic("180D", "2A19");
await bleService.writeCharacteristic("180D", "2A37", [72, 98]);
```

---

## 📊 Parse Data

```dart
// Dữ liệu từ device: List<int>

// Heart Rate (1 byte)
int heartRate = data[0];  // 0-255 bpm

// SpO2 (1 byte)
int spo2 = data[0];  // 0-100 %

// 2 bytes (big-endian)
int value = (data[0] << 8) | data[1];

// 2 bytes (little-endian)
int value = (data[1] << 8) | data[0];

// Flags + Value
if ((data[0] & 0x01) == 0) {
  // uint8
  int hr = data[1];
} else {
  // uint16
  int hr = (data[1] << 8) | data[2];
}
```

---

## 🎨 UI Quick Build

### Card Widget
```dart
Card(
  color: Colors.blue[50],
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(children: [
      Icon(Icons.favorite, size: 48),
      Text("72 bpm", style: TextStyle(fontSize: 32)),
    ]),
  ),
)
```

### List Tile
```dart
ListTile(
  leading: Icon(Icons.bluetooth),
  title: Text("Device Name"),
  subtitle: Text("MAC: 00:11:22:33:44:55"),
  trailing: ElevatedButton(
    onPressed: () => connectDevice(),
    child: Text("Connect"),
  ),
)
```

---

## 🔧 Debug Tricks

### Print All Services
```dart
var services = bleService.getDiscoveredServices();
for (var svc in services ?? []) {
  print("Service: ${svc.uuid}");
  for (var chr in svc.characteristics) {
    print("  - ${chr.uuid} (${chr.properties})");
  }
}
```

### Check Characteristic Properties
```dart
var char = bleService.getCharacteristic("180D", "2A37");
print("read: ${char?.properties.read}");
print("notify: ${char?.properties.notify}");
print("indicate: ${char?.properties.indicate}");
print("write: ${char?.properties.write}");
```

### Log Raw Bytes
```dart
stream?.listen((data) {
  print("Raw bytes: ${data.map((b) => b.toRadixString(16)).join(' ')}");
  print("As decimal: $data");
});
```

---

## ⚠️ Common Issues

| Problem | Solution |
|---------|----------|
| "Device not found" | Check device is powered on & in range |
| "Permission denied" | Go to Settings > [App] > Permissions |
| "No characteristics" | Device didn't discover services properly |
| "No data received" | Characteristic might not have notify property |
| "Connection timeout" | Device too far, increase timeout |
| "Build error (iOS)" | Run `flutter clean && flutter pub get` |

---

## 📱 Platform-Specific

### Android Permissions
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS Config
```xml
<!-- Info.plist -->
<key>NSBluetoothPeripheralUsageDescription</key>
<string>App needs Bluetooth to connect to health devices</string>
<key>NSBluetoothCentralUsageDescription</key>
<string>App needs Bluetooth to scan devices</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>App needs location for BLE scanning</string>
```

---

## 🎯 Quick Customization

### Change UUID
```dart
// In connect_screen.dart
var stream = await bleService.subscribeToCharacteristic(
  "YOUR_SERVICE_UUID",    // Change this
  "YOUR_CHARACTERISTIC_UUID",  // Change this
);
```

### Change Parse Logic
```dart
// In _processHeartRateData()
// Replace this:
// int heartRate = data[0];

// With your logic:
if (data.length >= 2) {
  int heartRate = (data[0] << 8) | data[1];  // 16-bit
}
```

### Add More Data Fields
```dart
// In connect_screen.dart, add:
int temperature = 0;
int battery = 0;

// Then subscribe to more characteristics:
_subscribeToTemperature();
_subscribeToBattery();
```

---

## 📚 Documentation Links

- Flutter: https://flutter.dev/docs
- flutter_blue_plus: https://pub.dev/packages/flutter_blue_plus
- permission_handler: https://pub.dev/packages/permission_handler
- BLE GATT: https://www.bluetooth.com/specifications/gatt

---

## 🧪 Testing Checklist

- [ ] App starts without crash
- [ ] Permissions dialog appears
- [ ] Scan finds device within 15s
- [ ] Device list shows correct names
- [ ] RSSI values update
- [ ] Click Connect → navigates to data screen
- [ ] Heart Rate displays (not 0)
- [ ] SpO2 displays (not 0)
- [ ] Data updates every ~1s
- [ ] History scrolls smoothly
- [ ] Disconnect works
- [ ] Can reconnect after disconnect

---

## 💡 Tips & Tricks

**1. Use BLE Scanner App to find UUIDs**
   - Download from Play Store/App Store
   - Find your device
   - Note down Service & Characteristic UUIDs

**2. Add debug prints everywhere**
   ```dart
   print("🔍 Scanning...");  // Easy to search for
   print("✅ Connected!");
   print("❌ Error: $e");
   ```

**3. Test on real device (not emulator)**
   - BLE emulation is limited
   - Real device gives better debugging info

**4. Keep device powered and in range**
   - BLE has ~10 meter range
   - Move device closer if connection fails

**5. Check device data format**
   - Use BLE Scanner app
   - Write down exact byte order
   - Test with simple data first

---

**Happy Coding! 🎉**
