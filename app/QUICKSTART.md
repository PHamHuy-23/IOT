# Quick Start Guide - ESP32C3-Watch Health Monitor

## 5-Minute Setup

### Step 1: Pair Your Watch (Phone Settings)
```
Settings → Bluetooth → Enable Bluetooth
→ Available Devices → ESP32C3-Watch → Pair
```
Wait for confirmation. You should see it listed under "Paired Devices".

### Step 2: Install Dependencies
```bash
cd g:/Desktop/IOT/app
flutter pub get
```

### Step 3: Set Permissions (Android)
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Step 4: Run the App
```bash
flutter run
```

### Step 5: Use the Dashboard
1. App auto-connects to paired watch
2. See real-time Heart Rate & SpO2
3. Watch the smooth wave chart update
4. Tap "Sync Time to Watch" to sync device time

---

## Architecture Highlights

✅ **System-Paired Device**: No constant re-scanning, persistent OS-managed connection  
✅ **Provider State Management**: Clean, testable, scalable  
✅ **Custom Wave Painter**: Smooth, medical-grade heart rate visualization  
✅ **Dark Medical Dashboard**: Modern, sleek UI with dynamic status colors  
✅ **Production-Ready**: Error handling, timeouts, resource cleanup  

---

## File Structure

```
lib/
├── main.dart                      ← App entry point
├── screens/dashboard_screen.dart  ← Main UI (NEW)
├── providers/health_provider.dart ← State management (NEW)
├── services/ble_service.dart      ← BLE operations (UPDATED)
├── painters/heart_rate_wave_painter.dart ← Wave visualization (NEW)
├── themes/app_theme.dart          ← Dark mode theme (NEW)
├── models/health_metrics.dart     ← Data models (NEW)
└── constants/ble_constants.dart   ← UUIDs & limits (UPDATED)
```

---

## Key Components

### HealthProvider
Manages all state:
- Connection status
- Real-time HR/SpO2 readings
- Heart rate history (60-point sliding window)
- Error handling

### BleService
Handles low-level BLE:
- System-paired device lookup
- Service discovery
- Data parsing (HR: `int bpm = data[1] | (data[2] << 8)`)
- Time sync commands

### DashboardScreen
Beautiful modern UI with:
- Connection status bar with glow effect
- Responsive HR display (color-coded by intensity)
- SpO2 circular progress indicator
- Smooth wave chart with grid
- One-tap time sync button
- Error notifications

---

## BLE Protocol (at a Glance)

| Metric | Service UUID | Characteristic UUID | Payload | Parse |
|--------|--------------|-------------------|---------|-------|
| **HR** | `180D` | `2A37` | 3 bytes: `[0x01, low, high]` | `data[1] \| (data[2]<<8)` |
| **SpO2** | `1809` | `2A5F` | 2 bytes: `[spo2, 0]` | `data[0]` |
| **Time** | `9f0f0001-...` | `9f0f0002-...` | 3 bytes: `[hour, min, sec]` | Write only |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Device not found | Verify paired in Settings → Bluetooth |
| Connection drops | Power cycle watch, ensure <10m distance |
| No HR/SpO2 data | Check watch sensors & debug logs |
| Permission errors | Grant Bluetooth perms in Settings |

---

## Testing Checklist

- [ ] App launches to dashboard
- [ ] Status shows "Connected to ESP32C3-Watch"
- [ ] HR readings display and update (even if 0 initially)
- [ ] HR wave chart smoothly animates
- [ ] SpO2 percentage displays correctly
- [ ] Status colors change based on values
- [ ] "Sync Time" button works without errors
- [ ] Disconnect → Reconnect works
- [ ] Pull-to-refresh re-attempts connection

---

## Next Steps

1. **Test Data**: Wear watch on finger to get real HR/SpO2
2. **Custom Alerts**: Add high/low HR alerts
3. **Data Logging**: Persist metrics to SQLite
4. **Export**: Add CSV export for health tracking

See `IMPLEMENTATION_GUIDE.md` for detailed architecture and extensibility.
