# Firmware ESP32-C3 — Vòng tay

## Gợi ý triển khai

1. **Device ID:** Lưu `deviceCode` trong NVS (vd MAC dạng `C3-AABBCCDDEEFF`)
2. **BLE GATT service** (UUID tùy chọn):
   - Characteristic đọc: `deviceCode`, `firmwareVersion`, `battery`
   - Characteristic ghi: `activation` (app gửi token nếu cần)
3. **Sau kích hoạt:** Gửi heartbeat định kỳ lên API (WiFi) hoặc app relay qua BLE
4. **OTA:** Dùng `esp_https_ota` — gọi `GET /devices/:code/firmware/check`, tải `.bin`, verify SHA256, flash partition `ota_1`

## Mã lỗi gợi ý

| Code | Ý nghĩa |
|------|---------|
| `E_SENSOR_HR` | Cảm biến nhịp tim |
| `E_SENSOR_SPO2` | Cảm biến SpO2 |
| `E_BLE_INIT` | Khởi tạo BLE thất bại |
| `E_BATTERY_LOW` | Pin yếu |

Gửi trong mảng `errorCodes` khi heartbeat.

## PlatformIO

Tạo project `esp32-c3-devkitm-1`, bật partition table OTA dual (`default.csv` hoặc `min_spiffs.csv` có `ota_0`, `ota_1`).

```ini
[env:esp32-c3]
platform = espressif32
board = esp32-c3-devkitm-1
framework = arduino
```

Bước tiếp: thêm sketch `src/main.cpp` với NimBLE hoặc BLE Arduino.
