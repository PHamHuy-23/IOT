# BLE Health Monitor

Ung dung Flutter theo doi suc khoe qua BLE, luu du lieu len Supabase va ho tro chia se/canh bao suc khoe cho nguoi than.

## Tong Quan

Du an gom cac phan chinh:

- Quet va ket noi thiet bi BLE bang `flutter_blue_plus`.
- Doc chi so nhip tim, SpO2 va trang thai te nga theo thoi gian thuc.
- Luu ban ghi suc khoe vao Supabase.
- Tong hop du lieu ngay/tuan/thang/nam.
- Dang nhap/dang ky bang Supabase Auth.
- Ho so nguoi dung, Medical ID, cai dat thong bao, chia se gia dinh va canh bao suc khoe.
- Che do mo phong du lieu cho tai khoan admin/testing khi khong co thiet bi BLE.

## Cau Truc Thu Muc

```text
lib/
  main.dart
  constants/
    ble_constants.dart
    health_alert_constants.dart
  models/
    ble_device_model.dart
    daily_summary_model.dart
    family_member.dart
    health_alert.dart
    health_metrics.dart
    user_medical_profile.dart
    user_settings.dart
  providers/
    alert_provider.dart
    auth_provider.dart
    family_share_provider.dart
    health_provider.dart
    supabase_provider.dart
    user_data_provider.dart
  screens/
    auth_screen.dart
    dashboard_screen.dart
    profile_screen.dart
    health_history_screen.dart
    health_alerts_screen.dart
    family_sharing_tab.dart
    scan_screen.dart
    connect_screen.dart
  services/
    ble_service.dart
    family_share_service.dart
    health_alert_service.dart
    health_data_service.dart
    local_notification_service.dart
    permission_service.dart
    simulated_health_service.dart
    supabase_service.dart
    user_profile_service.dart
  widgets/
    provider_binder.dart
```

## Cai Dat

Yeu cau:

- Flutter SDK.
- Android Studio/Xcode neu chay tren mobile.
- Supabase project.
- Thiet bi that de test BLE. Emulator thuong khong phu hop cho BLE.

Cai dependencies:

```bash
flutter pub get
```

Tao file `.env` o thu muc goc app:

```env
url=https://YOUR_PROJECT.supabase.co
anonKey=YOUR_SUPABASE_ANON_KEY
```

Chay app:

```bash
flutter run
```

## Supabase

Chay cac file SQL theo thu tu neu tao database moi:

1. `supabase_schema.sql`
2. `supabase_migration_v2.sql`
3. `supabase_migration_v3_family.sql`
4. `supabase_migration_v4_alerts.sql`
5. `supabase_migration_v5_auth_login.sql`

Luu y quan trong ve auth:

- App hien dang dung Supabase Auth qua `signInWithPassword`.
- `public.users` chi la bang profile/meta.
- `public.users.password_hash` khong duoc Supabase Auth dung de dang nhap.
- Moi tai khoan muon dang nhap phai ton tai trong `Authentication > Users` cua Supabase.
- `public.users.id` nen trung voi `auth.users.id`, vi app load profile bang user id tu Supabase Auth.
- Migration v5 tao RPC `resolve_login_email` de nguoi dung co the nhap username, app se doi sang email truoc khi goi Supabase Auth.

Neu bi `Invalid login credentials`, hay kiem tra:

- Email/password co dung trong Supabase Authentication khong.
- Email trong `public.users` co trung voi email trong Auth khong.
- User trong `public.users` co id trung voi Auth user id khong.
- Da chay `supabase_migration_v5_auth_login.sql` chua neu dang nhap bang username.

## Luong Dang Nhap

1. `main.dart` khoi tao Supabase va `AuthProvider`.
2. `AuthProvider.initialize()` doc session hien co cua Supabase SDK.
3. Neu co session hop le, app vao `DashboardScreen`.
4. Neu chua co session, app vao `AuthScreen`.
5. Khi login:
   - Neu input la email, login truc tiep.
   - Neu input la username, goi RPC `resolve_login_email` de lay email.
   - Sau khi Supabase Auth thanh cong, app load profile tu `public.users`.

## Luong BLE

1. App xin quyen Bluetooth/Location qua `PermissionService`.
2. `BleService` quet thiet bi.
3. Nguoi dung chon thiet bi hoac app auto-connect theo logic trong `HealthProvider`.
4. App discover services/characteristics.
5. App subscribe notification/read data tu thiet bi.
6. Du lieu duoc parse thanh nhip tim, SpO2, canh bao te nga.
7. Du lieu hop le duoc luu vao Supabase bang service/provider tuong ung.

## UUID Va Cau Hinh BLE

Kiem tra `lib/constants/ble_constants.dart` de doi UUID cho dung voi firmware/thiet bi cua ban.

Neu khong thay du lieu:

- Dung app BLE Scanner de xem device co advertise khong.
- Kiem tra service UUID va characteristic UUID.
- Dam bao characteristic co quyen `notify` hoac `read`.
- Tren Android, khong nen pair ESP32 tu Bluetooth Settings neu app tu ket noi truc tiep qua BLE.
- Bat Location neu Android yeu cau de scan BLE.

## Man Hinh Chinh

- `AuthScreen`: dang nhap/dang ky.
- `DashboardScreen`: man tong quan suc khoe, tab browse, chia se gia dinh, Medical ID.
- `ProfileScreen`: ho so nguoi dung va dang xuat.
- `HealthHistoryScreen`: lich su chi so.
- `HealthAlertsScreen`: danh sach canh bao.
- `ScanScreen` va `ConnectScreen`: luong scan/connect BLE co ban.
- `AdminTestPanelScreen`: test canh bao/mo phong cho admin/testing.

## Providers Va Services

- `AuthProvider`: quan ly session, profile, dang nhap/dang ky/dang xuat.
- `HealthProvider`: quan ly ket noi BLE, du lieu realtime, mo phong.
- `UserDataProvider`: daily summary, settings, medical profile.
- `FamilyShareProvider`: thanh vien/chia se gia dinh.
- `AlertProvider`: canh bao suc khoe va te nga.
- `ProviderBinder`: noi cac provider voi nhau khi user thay doi.

## Debug Nhanh

Lenh hay dung:

```bash
flutter pub get
flutter analyze
flutter run
flutter clean
```

Khi loi Supabase:

- Kiem tra `.env`.
- Kiem tra SQL migration da chay het chua.
- Kiem tra RLS policy.
- Kiem tra user dang nhap co row trong `public.users` khong.

Khi loi BLE:

- Kiem tra quyen runtime.
- Kiem tra Bluetooth da bat.
- Kiem tra UUID trong code.
- Test tren may that.

## Trang Thai Hien Tai

- App da chuyen luong dang nhap sang Supabase Auth.
- Da them migration v5 de ho tro login bang username.
- `main.dart` da dieu huong theo trang thai dang nhap thay vi vao dashboard mac dinh.
- Can chay migration v5 tren Supabase va tao/migrate Auth users dung cach de cac tai khoan cu dang nhap duoc.
