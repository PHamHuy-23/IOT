/// Các hằng số và UUID dùng cho BLE communication

// ============ Standard GATT Service UUIDs ============
const String HEART_RATE_SERVICE_UUID = "180D"; // Heart Rate Service
const String SPO2_SERVICE_UUID = "1809"; // Health Thermometer Service
const String CUSTOM_HEALTH_SERVICE_UUID =
    "0000181A-0000-1000-8000-00805f9b34fb"; // Health Service (optional)

// ============ Standard GATT Characteristic UUIDs ============
const String HEART_RATE_MEASUREMENT_UUID = "2A37"; // Heart Rate Measurement
const String SPO2_MEASUREMENT_UUID = "2A5F"; // Firmware SpO2 characteristic
const String BATTERY_LEVEL_UUID = "2A19"; // Battery Level
const String DEVICE_NAME_UUID = "2A00"; // Device Name

// ============ Custom UUIDs (Có thể thay đổi tùy thiết bị) ============
// Ví dụ cho thiết bị custom
const String CUSTOM_HEART_RATE_UUID =
    "0000FFF1-0000-1000-8000-00805f9b34fb"; // Custom HR characteristic
const String CUSTOM_SPO2_UUID = "0000FFF2-0000-1000-8000-00805f9b34fb"; // Custom SpO2 characteristic

// ============ Scan Settings ============
const int SCAN_TIMEOUT_SECONDS = 15; // Thời gian quét tối đa
const int DEVICE_CONNECT_TIMEOUT_SECONDS = 10; // Thời gian kết nối tối đa

// ============ Data Constants ============
const int MAX_HEART_RATE = 220; // Nhịp tim tối đa
const int MIN_HEART_RATE = 40; // Nhịp tim tối thiểu
const int MAX_SPO2 = 100; // SpO2 tối đa
const int MIN_SPO2 = 0; // SpO2 tối thiểu

// Function chuyển đổi UUID từ dạng 16-bit sang full format
String getFullUuid(String shortUuid) {
  if (shortUuid.length == 4) {
    return "0000$shortUuid-0000-1000-8000-00805f9b34fb";
  }
  return shortUuid;
}
