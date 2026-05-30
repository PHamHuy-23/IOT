# API Reference — Mobile & Firmware

Base URL: `http://localhost:4000/api` (dev)

## Auth (app người dùng)

### Đăng ký
`POST /auth/register-user`
```json
{ "email": "user@mail.com", "password": "secret", "name": "Tên", "phone": "09..." }
```

### Đăng nhập
`POST /auth/login`
```json
{ "email": "user@mail.com", "password": "secret" }
```
Response: `{ "token": "...", "user": { ... } }`

---

## Kích hoạt vòng tay (sau BLE)

`POST /devices/activate`  
Header: `Authorization: Bearer <token>`

```json
{
  "deviceCode": "C3-A1B2C3D4E5F6",
  "model": "ESP32-C3-BAND",
  "firmwareVersion": "1.0.0"
}
```

`deviceCode` nên lấy từ:
- BLE characteristic (khuyến nghị)
- Hoặc MAC/serial in trên vòng tay

Response gồm `device` + `user` — admin web đọc cùng dữ liệu qua `/admin/devices`.

---

## Heartbeat / telemetry (ESP32 hoặc app relay)

`POST /devices/:deviceCode/heartbeat`

```json
{
  "firmwareVersion": "1.0.0",
  "heartRate": 75,
  "spo2": 98,
  "steps": 1200,
  "battery": 80,
  "errorCodes": ["E_BLE_INIT"]
}
```

---

## OTA (firmware ESP32)

### Kiểm tra bản mới
`GET /devices/:deviceCode/firmware/check`

```json
{
  "updateAvailable": true,
  "currentVersion": "1.0.0",
  "targetVersion": "1.0.1",
  "downloadUrl": "http://.../api/ota/firmware/xxx/download",
  "checksum": "sha256...",
  "campaignId": "..."
}
```

### Báo cáo tiến trình OTA
`POST /devices/:deviceCode/ota/report`

```json
{
  "campaignId": "...",
  "status": "success",
  "message": "optional"
}
```

`status`: `downloading` | `success` | `failed`

---

## Admin (web)

| Method | Path | Mô tả |
|--------|------|--------|
| GET | `/admin/stats` | Dashboard counts |
| GET | `/admin/devices` | Danh sách thiết bị |
| GET | `/admin/users` | Người dùng + devices |
| POST | `/admin/devices/register` | Pre-register mã |
| POST | `/ota/firmware` | Upload .bin (multipart) |
| POST | `/ota/campaigns/:id/start` | Bắt đầu rollout |

Tất cả `/admin/*` và `/ota/*` (trừ download) cần JWT role `ADMIN`.
