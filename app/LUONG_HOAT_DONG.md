# 🔄 LUỒNG HOẠT ĐỘNG (DATA FLOW) 

## 📱 Startup Flow

```
┌─────────────────────────────────┐
│  App Starts (main.dart)         │
│  → ScanScreen()                 │
└──────────────┬──────────────────┘
               │
        ┌──────▼────────┐
        │  Check Perms  │
        │  initState()  │
        └──────┬────────┘
               │
      ┌────────▼────────┐
      │ Permission OK?  │
      └────┬──────┬─────┘
          yes     no
           │       │
           │    Request
           │    Perms
           │       │
       ┌───┴───────┴──────┐
       │   Ready to Scan  │
       │   statusMessage  │
       └──────────────────┘
```

---

## 🔍 Scan Flow

```
┌─────────────────────────────┐
│  User: "Bắt Đầu Quét"       │
└──────────────┬──────────────┘
               │
        ┌──────▼───────────────┐
        │  startScan()         │
        │  (BleService)        │
        │  timeout: 15 sec     │
        └──────┬───────────────┘
               │
    ┌──────────┴──────────┐
    │  Scan Results Stream  │
    │  onValueChange()      │
    └──────┬───────────────┘
           │
    ┌──────▼──────────┐
    │  Filter Device  │
    │  Remove Duplic. │
    └──────┬──────────┘
           │
    ┌──────▼───────────────┐
    │  Add to List          │
    │  setState()           │
    │  Update UI            │
    └──────┬───────────────┘
           │
    ┌──────▼────────────┐
    │  15s Timeout      │
    │  Auto stopScan()  │
    └───────────────────┘
```

---

## 🔗 Connect Flow

```
┌──────────────────────────────┐
│  User: "Kết Nối" [Device]   │
└────────────────┬─────────────┘
                 │
          ┌──────▼──────────────┐
          │  connectToDevice()  │
          │  (BleService)       │
          │  timeout: 10 sec    │
          └──────┬──────────────┘
                 │
          ┌──────▼──────────────┐
          │  Kết nối thành công │
          │  discoverServices() │
          │  (Tự động)          │
          └──────┬──────────────┘
                 │
    ┌────────────▼────────────┐
    │  Get List of Services   │
    │  & Characteristics      │
    │                         │
    │  Ví dụ:                 │
    │  ├─ Service 180D (HR)   │
    │  │  └─ Char 2A37        │
    │  ├─ Service FFF0        │
    │  │  ├─ Char FFF1 (HR)   │
    │  │  └─ Char FFF2 (SpO2) │
    │  └─ Service 180A        │
    │     └─ Char 2A19 (Batt) │
    │                         │
    └────────────┬────────────┘
                 │
    ┌────────────▼────────────┐
    │  Store Services List    │
    │  (_discoveredServices)  │
    │  Ready for Subscribe    │
    └────────────────────────┘
```

---

## 📡 Subscribe & Listen Flow

```
┌────────────────────────────────────────┐
│  ConnectScreen.initState()             │
└─────────────┬────────────────────────┘
              │
      ┌───────▼──────────────────────┐
      │  _startListeningToData()     │
      └───────┬──────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼─────────────┐  ┌──▼────────────┐
│ Heart Rate      │  │  SpO2         │
│ Subscribe       │  │  Subscribe    │
└───┬─────────────┘  └──┬────────────┘
    │                   │
┌───▼──────────────────────────────┐
│  subscribeToCharacteristic()     │
│  (Try Standard UUID first)       │
└───┬──────────────────────────────┘
    │
    ├─ 180D / 2A37 ✓ Found?
    │  └─ YES: Stream from it
    │  └─ NO: Try Custom UUID
    │
    └─ FFF0 / FFF1 ✓ Found?
       └─ YES: Stream from it
       └─ NO: Skip
```

---

## 📊 Data Receive & Parse Flow

```
┌──────────────────────────────────┐
│  Device Sends Data:              │
│  [HR_byte, SpO2_byte, ...]      │
└──────────────┬───────────────────┘
               │
        ┌──────▼──────────────────┐
        │  onValueReceived Stream  │
        │  (characteristic)        │
        └──────┬───────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼──────────────┐   ┌──▼────────────┐
│  Heart Rate      │   │  SpO2         │
│  Data Stream     │   │  Data Stream  │
│  [byte0, ...]    │   │  [byte0, ...] │
└───┬──────────────┘   └──┬────────────┘
    │                     │
│   _processHeartRateData()   │   _processSpO2Data()
│   (List<int> data)          │   (List<int> data)
│   {                         │   {
│     int hr = data[0]        │     int spo2 = data[0]
│     if (hr in range?) {     │     if (spo2 in range?) {
│       setState(hr)          │       setState(spo2)
│       lastUpdateTime        │       addToHistory()
│     }                       │     }
│   }                         │   }
│                             │
└─────────────┬───────────────┘
              │
       ┌──────▼──────────┐
       │  Update UI      │
       │  ┌────────────┐ │
       │  │ ❤️ HR      │ │
       │  │ 72 bpm     │ │
       │  │ Bình thường │ │
       │  └────────────┘ │
       │  ┌────────────┐ │
       │  │ 💨 SpO2    │ │
       │  │ 98 %       │ │
       │  │ Bình thường │ │
       │  └────────────┘ │
       │  History: [...] │
       └─────────────────┘
```

---

## 🔌 Disconnect Flow

```
┌──────────────────────────┐
│  User: "Ngắt Kết Nối"    │
└────────────┬─────────────┘
             │
      ┌──────▼──────────┐
      │ Unsubscribe()   │
      │ All Services    │
      └──────┬──────────┘
             │
      ┌──────▼──────────┐
      │ disconnect()    │
      │ (BleService)    │
      └──────┬──────────┘
             │
      ┌──────▼──────────┐
      │ Clear Data      │
      │ _connectedDev   │
      │ = null          │
      └──────┬──────────┘
             │
      ┌──────▼──────────┐
      │ Pop Screen      │
      │ Back to Scan    │
      └──────────────────┘
```

---

## 🗂️ Class Interaction Diagram

```
┌────────────────────────────────────────────────────┐
│                   main.dart                        │
│              MaterialApp → ScanScreen             │
└────────────────────┬───────────────────────────────┘
                     │
        ┌────────────┴──────────────┐
        │                           │
┌───────▼──────────┐        ┌──────▼──────────┐
│  ScanScreen      │        │ ConnectScreen   │
│  (StatefulWidget)│        │ (StatefulWidget)│
│                  │        │                 │
│ • _bleService    │        │ • device        │
│ • discoveredDev  │        │ • bleService    │
│ • isScanning     │        │ • heartRate     │
│ • statusMessage  │        │ • spo2          │
│                  │        │ • dataHistory   │
│ Methods:         │        │ • lastUpdateTime│
│ • _startScan()   │        │                 │
│ • _stopScan()    │        │ Methods:        │
│ • _connectToDev()│        │ • _subscribe..()│
└────────┬─────────┘        │ • _process..()  │
         │                  │ • _disconnect() │
         │                  └────────┬────────┘
         │                          │
         └──────────┬───────────────┘
                    │
          ┌─────────▼──────────┐
          │   BleService       │
          │  (Singleton)       │
          │                    │
          │ • _connectedDev    │
          │ • _discoveredServ  │
          │ • scanResults      │
          │                    │
          │ Methods:           │
          │ • startScan()      │
          │ • connectToDevice()│
          │ • discoverServices()
          │ • subscribeToChar()│
          │ • readChar()       │
          │ • writeChar()      │
          │ • disconnect()     │
          └─────────┬──────────┘
                    │
          ┌─────────▼──────────┐
          │ FlutterBluePlus    │
          │ (External Package) │
          └────────────────────┘
```

---

## 📦 Data Model

```
BleDeviceModel
├── device: BluetoothDevice
├── deviceName: String
├── deviceId: String (MAC/UUID)
├── rssi: int (Signal Strength)
├── isConnecting: bool
├── isConnected: bool
├── Methods:
│   ├── updateConnectionStatus(bool)
│   ├── getDisplayName(): String
│   └── getSignalStrength(): String
└── HealthData
    ├── heartRate: int
    ├── spo2: int
    ├── timestamp: DateTime
    └── Methods:
        └── isValid(): bool
```

---

## 🔑 Key Constants (ble_constants.dart)

```
HEART_RATE_SERVICE_UUID = "180D"
HEART_RATE_MEASUREMENT_UUID = "2A37"
CUSTOM_HEALTH_SERVICE_UUID = "0000181A-..."
CUSTOM_HEART_RATE_UUID = "0000FFF1-..."
CUSTOM_SPO2_UUID = "0000FFF2-..."

SCAN_TIMEOUT_SECONDS = 15
DEVICE_CONNECT_TIMEOUT_SECONDS = 10
MAX_HEART_RATE = 220
MIN_HEART_RATE = 40
MAX_SPO2 = 100
MIN_SPO2 = 0
```

---

## 🎯 Permission Flow

```
┌──────────────────────────────┐
│  App Starts                  │
└────────────┬─────────────────┘
             │
      ┌──────▼──────────────────┐
      │ PermissionService       │
      │ hasBluetoothPermission()│
      └──────┬───────────────────┘
             │
      ┌──────▼────────┐
      │ All Perms OK? │
      └────┬──────┬───┘
          yes     no
           │       │
           │    requestBluetoothPermissions()
           │    ├─ BLUETOOTH
           │    ├─ BLUETOOTH_CONNECT
           │    ├─ BLUETOOTH_SCAN
           │    └─ ACCESS_FINE_LOCATION
           │       │
       ┌───┴───────┴──┐
       │ User Approves │
       │      or       │
       │   Denies      │
       └────┬──────┬───┘
           yes     no
            │       │
     Ready   │   openAppSettings()
             │   (User cấp thủ công)
             │
       ┌─────┴──────┐
       │  Can Scan  │
       └────────────┘
```

---

## 💾 State Management Flow

```
┌───────────────────────────────────┐
│  ScanScreen State                 │
│                                   │
│ discoveredDevices: List<BleDevice)
│ isScanning: bool                  │
│ statusMessage: String             │
│                                   │
│ setState() → Rebuild UI           │
└───────────────┬───────────────────┘
                │
        ┌───────▼─────────┐
        │ Listen Stream   │
        │ bleService.scan │
        │ Results         │
        └───────┬─────────┘
                │
        ┌───────▼──────────┐
        │ Update List      │
        │ setState() ×N    │
        └──────────────────┘
```

---

**Hiểu rõ luồng này sẽ giúp bạn dễ dàng tùy chỉnh và mở rộng ứng dụng! 🎯**
