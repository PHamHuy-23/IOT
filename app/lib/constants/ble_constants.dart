/// Các hằng số và UUID dùng cho BLE communication với ESP32C3-Watch

// ============ Device Configuration ============
const String TARGET_DEVICE_NAME = "ESP32C3-Watch";

// ============ Heart Rate Service ============
const String HEART_RATE_SERVICE_UUID = "0000180D-0000-1000-8000-00805f9b34fb";
const String HEART_RATE_MEASUREMENT_UUID = "00002A37-0000-1000-8000-00805f9b34fb";
// Property: Notify | Payload: 3 bytes
// Format: byte[0] = 0x01, byte[1] = bpm low, byte[2] = bpm high

// ============ Blood Oxygen (SpO2) Service ============
const String SPO2_SERVICE_UUID = "00001809-0000-1000-8000-00805f9b34fb";
const String SPO2_MEASUREMENT_UUID = "00002A5F-0000-1000-8000-00805f9b34fb";
// Property: Notify + Read | Payload: 2 bytes
// Format: byte[0] = spo2 integer, byte[1] = decimal (always 0)

// ============ Time Synchronization Service ============
const String TIME_SYNC_SERVICE_UUID = "9f0f0001-7b35-4f20-8a61-5d3b8a7a0001";
const String TIME_SYNC_CHARACTERISTIC_UUID = "9f0f0002-7b35-4f20-8a61-5d3b8a7a0001";
// Property: Write + Write Without Response | Payload: 3 bytes
// Format: byte[0] = hour (0-23), byte[1] = minute (0-59), byte[2] = second (0-59)

// ============ Scan Settings ============
const int SCAN_TIMEOUT_SECONDS = 15;
const int DEVICE_CONNECT_TIMEOUT_SECONDS = 10;

// ============ Data Constants ============
const int MAX_HEART_RATE = 220;
const int MIN_HEART_RATE = 40;
const int MAX_SPO2 = 100;
const int MIN_SPO2 = 0;

// ============ Chart Constants ============
const int HEART_RATE_HISTORY_MAX_POINTS = 60;
const Duration HEART_RATE_UPDATE_INTERVAL = Duration(seconds: 1);

String getFullUuid(String shortUuid) {
  if (shortUuid.length == 4) {
    return "0000$shortUuid-0000-1000-8000-00805f9b34fb";
  }
  return shortUuid;
}
