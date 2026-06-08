# Hướng dẫn Setup Supabase cho Ứng dụng Giám sát Sức khỏe

## 1. Tạo Supabase Project

### Bước 1: Đăng ký tài khoản Supabase
- Truy cập [Supabase](https://supabase.com)
- Đăng ký hoặc đăng nhập tài khoản
- Click "New Project"

### Bước 2: Tạo Project mới
- Database name: `health_monitor`
- Password: Tạo mật khẩu mạnh
- Region: Chọn gần nhất với khu vực của bạn (VN: Singapore)
- Click "Create new project"
- Chờ 1-2 phút để project khởi tạo

### Bước 3: Lấy thông tin kết nối
- Vào **Settings** → **API** → **URL**
- Copy URL (ví dụ: `https://xxxxx.supabase.co`)
- Copy **anon key** từ mục "Project API keys"

## 2. Cấu hình Flutter App

### Bước 1: Update pubspec.yaml
```yaml
supabase_flutter: ^1.11.0
```

### Bước 2: Cập nhật main.dart
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );

  runApp(const MyApp());
}
```

## 3. Import Database Schema

### Bước 1: Truy cập SQL Editor
- Vào Supabase console
- Mở **SQL Editor**

### Bước 2: Chạy SQL Schema
- Copy toàn bộ nội dung từ `supabase_schema.sql`
- Dán vào SQL Editor
- Click **Run**
- Chờ tới khi tất cả queries hoàn thành

### Bước 3: Xác nhận Tables
- Vào **Database** → **Tables**
- Kiểm tra xem 3 bảng sau đã tạo:
  - `users`
  - `health_records`
  - `daily_summary`

## 4. Cấu hình Authentication

### Bước 1: Enable Email/Password Auth
- Vào **Authentication** → **Providers**
- Tìm "Email"
- Bật "Enable Email provider"
- Click "Save"

### Bước 2: Cấu hình Email Settings (tùy chọn)
- Vào **Authentication** → **Email Templates**
- Customize nếu cần

## 5. Cấu hình Environment Variables

### Tạo file `.env`
```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 6. Sử dụng SupabaseService

### Khởi tạo
```dart
final supabaseService = SupabaseService();
```

### Đăng ký tài khoản
```dart
await supabaseService.signUp(
  email: 'user@example.com',
  password: 'password123',
  username: 'username',
);
```

### Đăng nhập
```dart
bool success = await supabaseService.signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

### Lưu dữ liệu sức khỏe
```dart
final metric = HealthMetrics(
  heartRate: 72,
  spO2: 98,
  timestamp: DateTime.now(),
);
await supabaseService.saveHealthMetric(metric);
```

### Lấy dữ liệu theo ngày
```dart
final today = await supabaseService.getTodayMetrics();
```

### Lấy dữ liệu theo khoảng thời gian
```dart
final start = DateTime(2026, 6, 1);
final end = DateTime(2026, 6, 8);
final metrics = await supabaseService.getMetricsByDateRange(start, end);
```

### Lấy tóm tắt theo ngày
```dart
final summary = await supabaseService.getDailySummary(DateTime.now());
// Returns: {avg_heart_rate, min_heart_rate, max_heart_rate, avg_spo2, min_spo2, max_spo2}
```

### Lấy tóm tắt theo tuần
```dart
final monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
final weeklySummary = await supabaseService.getWeeklySummary(monday);
```

### Lấy tóm tắt theo tháng
```dart
final monthlySummary = await supabaseService.getMonthlySummary(2026, 6);
```

### Lấy tóm tắt theo năm
```dart
final yearlySummary = await supabaseService.getYearlySummary(2026);
```

### Xóa dữ liệu cũ (>1 năm)
```dart
await supabaseService.deleteOldRecords();
```

## 7. Tính năng tự động

### Automatic Daily Summary
- Database tự động tính toán thống kê hàng ngày khi mỗi bản ghi mới được thêm
- Được cập nhật thông qua trigger: `health_records_insert_trigger`

### Automatic Cleanup
- Gọi `deleteOldRecords()` để xóa dữ liệu > 1 năm
- Hoặc cấu hình Cron job trong Supabase (Supabase Dashboard → Database → Extensions → pg_cron)

## 8. Row Level Security (RLS)

Tất cả người dùng chỉ có thể nhìn thấy dữ liệu của riêng họ nhờ RLS policies:
- `users`: Chỉ có thể xem/sửa profile của chính họ
- `health_records`: Chỉ có thể xem/thêm records của chính họ
- `daily_summary`: Chỉ có thể xem summary của chính họ

## 9. Troubleshooting

### Lỗi: "User not authenticated"
- Kiểm tra `signIn()` hoặc `signUp()` đã thành công
- Kiểm tra token expiration

### Lỗi: "Policy violation"
- Xác nhận user đã authenticated
- Kiểm tra RLS policies đã enable đúng cách

### Database không tự update daily summary
- Kiểm tra trigger `health_records_insert_trigger` đã tạo
- Chạy lại SQL schema

## 10. Backup Plan

### Backup dữ liệu định kỳ
- Supabase tự động backup 2 lần mỗi ngày
- Hoặc export manual từ **Backups** tab trong Supabase
