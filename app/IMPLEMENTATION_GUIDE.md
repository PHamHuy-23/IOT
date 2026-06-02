# ESP32C3-Watch Health Monitor - Flutter Implementation Guide

## Architecture Overview

This is a production-ready Flutter app for monitoring heart rate and blood oxygen from an ESP32C3-Watch via BLE, using **system-paired device management** instead of raw scanning.

### Key Design Decisions

#### 1. **System-Paired Device Approach (Critical)**
- **Why**: Instead of scanning for devices on every app launch, we leverage the phone's native Bluetooth pairing system
- **How**: User pairs "ESP32C3-Watch" via Phone Settings → Bluetooth → Available Devices
- **Benefit**: 
  - Persistent connection maintained by OS
  - App doesn't drain battery re-scanning constantly
  - Resembles how Bluetooth earphones work
  - No background permission complexity

#### 2. **Provider for State Management**
- Centralized `HealthProvider` manages:
  - BLE connection state
  - Real-time health metrics (HR, SpO2)
  - Heart rate history (sliding window of 60 points)
  - Error handling and UI feedback

#### 3. **Custom Wave Painter**
- Smooth quadratic Bézier curve rendering heart rate history
- Dynamic min/max scaling for responsive visualization
- Includes grid lines and fill overlay for medical dashboard aesthetic

---

## Project Structure

```
lib/
├── main.dart                      # App entry + Provider setup
├── constants/
│   └── ble_constants.dart         # UUID definitions & limits
├── models/
│   ├── health_metrics.dart        # HealthMetrics, HeartRateHistory classes
│   └── ble_device_model.dart      # (Legacy, can be removed)
├── services/
│   ├── ble_service.dart           # Singleton BLE operations
│   └── permission_service.dart    # Runtime permission handling
├── providers/
│   └── health_provider.dart       # Provider state management
├── painters/
│   └── heart_rate_wave_painter.dart # Custom wave visualization
├── themes/
│   └── app_theme.dart             # Dark mode medical dashboard colors
└── screens/
    ├── dashboard_screen.dart      # Main UI (NEW - replaces scan_screen)
    ├── scan_screen.dart           # (Legacy, can be removed)
    └── connect_screen.dart        # (Legacy, can be removed)
```

---

## BLE Protocol Specifications

### Heart Rate (HR)
- **Service UUID**: `0000180D-0000-1000-8000-00805f9b34fb`
- **Characteristic UUID**: `00002A37-0000-1000-8000-00805f9b34fb`
- **Property**: Notify
- **Payload**: 3 bytes
  ```
  byte[0] = 0x01 (flags)
  byte[1] = BPM low byte
  byte[2] = BPM high byte
  ```
- **Parsing**: `int bpm = data[1] | (data[2] << 8);`

### Blood Oxygen (SpO2)
- **Service UUID**: `00001809-0000-1000-8000-00805f9b34fb`
- **Characteristic UUID**: `00002A5F-0000-1000-8000-00805f9b34fb`
- **Property**: Notify + Read
- **Payload**: 2 bytes
  ```
  byte[0] = SpO2 percentage (0-100)
  byte[1] = decimal (always 0)
  ```
- **Parsing**: `int spo2 = data[0];`

### Time Synchronization (App → Watch)
- **Service UUID**: `9f0f0001-7b35-4f20-8a61-5d3b8a7a0001`
- **Characteristic UUID**: `9f0f0002-7b35-4f20-8a61-5d3b8a7a0001`
- **Property**: Write + Write Without Response
- **Payload**: 3 bytes
  ```
  byte[0] = hour (0-23)
  byte[1] = minute (0-59)
  byte[2] = second (0-59)
  ```
- **Usage**:
  ```dart
  await bleService.syncTime(DateTime.now());
  ```

---

## Setup Instructions

### 1. Install Dependencies
```bash
cd g:/Desktop/IOT/app
flutter pub get
```

### 2. Configure Platform-Specific Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs access to Bluetooth to connect to your health watch</string>
<key>NSBluetoothCentralUsageDescription</key>
<string>This app needs access to Bluetooth to monitor your health metrics</string>
```

### 3. Pairing the Device (User Steps)
1. Go to **Phone Settings → Bluetooth**
2. Enable Bluetooth
3. Tap **Available Devices**
4. Select **ESP32C3-Watch**
5. Confirm pairing
6. Return to the app and tap **Connect Watch**

### 4. Run the App
```bash
flutter run
```

---

## Usage Flow

### First-Time Setup
1. User opens app → Dashboard Screen appears
2. Dashboard calls `autoConnectToWatch()` automatically
3. App queries `FlutterBluePlus.connectedDevices`
4. Finds system-paired "ESP32C3-Watch"
5. Initiates connection and discovers services
6. Subscribes to HR and SpO2 streams
7. Real-time metrics display on UI

### Real-Time Data Flow
```
Watch (BLE Notify) 
  ↓
BleService.subscribeToHeartRate/SpO2()
  ↓
Parse payload (parseHeartRate / parseSpO2)
  ↓
HealthProvider._updateHeartRate/SpO2()
  ↓
UI rebuilds via Consumer<HealthProvider>
  ↓
Custom painters render latest data
```

### Time Sync
- User taps **"Sync Time to Watch"** button
- App sends current device time to watch
- Watch receives [hour, minute, second] as bytes
- Watch updates its internal clock

---

## Key Classes & Methods

### BleService (Singleton)
```dart
// Connection
Future<void> connectToDevice(BluetoothDevice device)
Future<void> disconnectDevice()

// Data Subscriptions
Stream<List<int>>? subscribeToHeartRate()
Stream<List<int>>? subscribeToSpO2()

// Parsing
int parseHeartRate(List<int> data)
int parseSpO2(List<int> data)

// Commands
Future<void> syncTime(DateTime time)

// Discovery
Future<void> discoverServices()
Future<void> setupCharacteristics()
```

### HealthProvider (Provider)
```dart
// Connection management
Future<void> autoConnectToWatch()
Future<void> connectToDevice(BluetoothDevice device)
Future<void> disconnectDevice()

// Data access
int get heartRate
int get spO2
HeartRateHistory get heartRateHistory

// Status
bool get isConnected
String get connectionStatus

// Commands
Future<void> syncTimeToWatch()
```

### DashboardScreen
- **Connection Status Card**: Shows live connection state with action buttons
- **Heart Rate Card**: Large BPM display + smooth wave chart
- **SpO2 Card**: Circular progress ring with status indicator
- **Sync Time Button**: Triggers time synchronization
- **Error Banner**: Displays connection/sync errors

---

## Theme & Colors

All colors defined in `AppTheme` class:
- **Deep Obsidian** (`#0B0E1B`): Main background
- **Dark Slate** (`#1A1F3A`): Cards & surfaces
- **Neon Cyan** (`#00D9FF`): SpO2 (good), borders
- **Neon Green** (`#00FF88`): Status indicators, SpO2 (excellent)
- **Electric Red** (`#FF1744`): HR danger, errors
- **Electric Pink** (`#FF4081`): HR wave, active state
- **Accent Purple** (`#7C3AED`): Primary CTA buttons

### Dynamic Color Mapping
```dart
// Heart Rate Status Color
AppTheme.getHeartRateColor(bpm)
  - 0 bpm → Grey
  - <60 → Cyan (low)
  - 60-100 → Green (normal)
  - 100-130 → Orange (elevated)
  - >130 → Red (high)

// SpO2 Status Color
AppTheme.getSpO2Color(spo2)
  - 0 → Grey
  - ≥95 → Green (excellent)
  - ≥90 → Cyan (good)
  - ≥85 → Orange (fair)
  - <85 → Red (low)
```

---

## Troubleshooting

### Device Not Found in Connected Devices
- **Issue**: App can't find "ESP32C3-Watch" in system paired devices
- **Solution**: 
  1. Verify device is paired in Phone Settings → Bluetooth
  2. Check device name matches `TARGET_DEVICE_NAME = "ESP32C3-Watch"`
  3. Power-cycle the watch and phone

### Connection Drops Immediately
- **Issue**: Connected but stream stops after seconds
- **Solution**:
  1. Increase `DEVICE_CONNECT_TIMEOUT_SECONDS` in constants
  2. Ensure watch is close to phone (BLE range ~10m)
  3. Check MTU negotiation (flutter_blue_plus handles this)

### No Data from Sensors
- **Issue**: HR/SpO2 show 0 even when connected
- **Solution**:
  1. Verify watch's BLE characteristics are actually notifying
  2. Check parsing logic in `parseHeartRate()` and `parseSpO2()`
  3. Enable logs: `print()` statements in `BleService`

### Permission Errors (Android)
- **Issue**: "Permission denied" when connecting
- **Solution**:
  1. Verify `AndroidManifest.xml` has all BLE permissions
  2. Grant runtime permissions at Settings → Apps → Health Monitor → Permissions
  3. Minimum API level: 21; Recommended: 31+

### App Freezes During Connect
- **Issue**: UI hangs while discovering services
- **Solution**:
  1. Services discovery runs on main thread by default
  2. Consider moving to background isolate for large service lists
  3. Add timeout handling in `discoverServices()`

---

## Performance Optimization Tips

1. **Heart Rate History Limit**: Currently 60 points (5 min @ 1Hz)
   - Adjust `HEART_RATE_HISTORY_MAX_POINTS` constant
   - Trade-off: More points = smoother curve but more memory

2. **Wave Painter Optimization**:
   - Uses quadratic Bézier curves (O(n) complexity)
   - Repaints only when data changes (`shouldRepaint`)
   - Consider caching if >100 points needed

3. **BLE Subscription Management**:
   - Unsubscribes in `disconnectDevice()` to avoid battery drain
   - Streams auto-close on provider disposal

4. **Memory**:
   - HeartRateHistory is bounded to 60 entries
   - Old timestamps/values auto-removed when limit exceeded

---

## Next Steps & Extensions

### Possible Enhancements
1. **Daily History**: Persist HR/SpO2 data to local SQLite
2. **Health Alerts**: Show warning when HR or SpO2 out of range
3. **Activity Tracking**: Log steps, calories from watch
4. **Export Data**: CSV/PDF export for medical review
5. **Multi-Device**: Support connecting multiple watches
6. **Settings Screen**: Allow user to adjust limits, units, theme

### Adding New Metrics
To add a new BLE characteristic (e.g., temperature, steps):
1. Add UUID constants to `ble_constants.dart`
2. Add subscription method to `BleService`
3. Add parser method to `BleService`
4. Add property to `HealthProvider`
5. Add UI card to `DashboardScreen`

---

## References

- **Flutter Blue Plus**: https://pub.dev/packages/flutter_blue_plus
- **Provider**: https://pub.dev/packages/provider
- **GATT Specifications**: https://www.bluetooth.com/specifications/gatt/
- **BLE Security**: https://en.wikipedia.org/wiki/Bluetooth_Low_Energy

