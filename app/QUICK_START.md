# Hướng dẫn Triển khai Nhanh - Database Supabase

## 🚀 Bắt đầu nhanh trong 10 phút

### 1️⃣ Tạo Supabase Project (2 phút)
```
1. Truy cập supabase.com
2. Đăng nhập → New Project
3. Điền: 
   - Name: health_monitor
   - Password: (tạo mật khẩu)
   - Region: Singapore
4. Click Create → Chờ khởi tạo
```

### 2️⃣ Import SQL Schema (2 phút)
```
1. Vào Supabase Console
2. Dashboard → SQL Editor
3. Click "New Query"
4. Copy toàn bộ nội dung từ file: supabase_schema.sql
5. Paste vào editor
6. Click "Run"
7. Xác nhận tất cả queries thành công
```

### 3️⃣ Lấy thông tin kết nối (1 phút)
```
1. Vào Settings → API
2. Copy:
   - Project URL: https://xxx.supabase.co
   - Anon Key: eyJhbGc...
```

### 4️⃣ Cập nhật Flutter Code (3 phút)

**Bước 1: Update pubspec.yaml**
```bash
flutter pub add supabase_flutter
```

**Bước 2: Cập nhật main.dart**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );

  runApp(const MyApp());
}
```

**Bước 3: Update main app providers (trong MyApp widget)**
```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => SupabaseProvider()),
    ChangeNotifierProvider(create: (_) => HealthProvider()),
  ],
  child: MaterialApp(
    home: Consumer<SupabaseProvider>(
      builder: (context, provider, _) {
        return provider.isAuthenticated
            ? const HealthDashboardScreen()
            : const LoginScreen();
      },
    ),
  ),
);
```

### 5️⃣ Chạy ứng dụng (2 phút)
```bash
flutter clean
flutter pub get
flutter run
```

## 💾 Database Schema

### Bảng chính
| Bảng | Mô tả |
|------|-------|
| `users` | Lưu thông tin người dùng (email, username) |
| `health_records` | Lưu dữ liệu nhịp tim & SpO2 thô từ sensor |
| `daily_summary` | Tóm tắt hàng ngày (trung bình, min, max) |

### Tự động cập nhật hàng ngày
- Khi thêm `health_records` mới → Tự động cập nhật `daily_summary`
- Thông qua trigger: `health_records_insert_trigger`

## 📱 Cách sử dụng trong app

### Lưu dữ liệu từ sensor
```dart
final provider = context.read<SupabaseProvider>();

final metric = HealthMetrics(
  heartRate: 72,
  spO2: 98,
  timestamp: DateTime.now(),
);

await provider.saveHealthMetric(metric);
```

### Lấy dữ liệu hôm nay
```dart
final todayMetrics = await provider.getTodayMetrics();
```

### Lấy thống kê hôm nay
```dart
final summary = await provider.getDailySummary(DateTime.now());
// {avg_heart_rate: 72, min_heart_rate: 68, max_heart_rate: 85, ...}
```

### Lấy thống kê tuần
```dart
final monday = DateTime.now().subtract(
  Duration(days: DateTime.now().weekday - 1),
);
final weeklySummary = await provider.getWeeklySummary(monday);
```

### Lấy thống kê tháng
```dart
final now = DateTime.now();
final monthlySummary = await provider.getMonthlySummary(now.year, now.month);
```

### Lấy thống kê năm
```dart
final yearlySummary = await provider.getYearlySummary(2026);
```

## 🔐 Bảo mật tự động

- ✅ Mỗi người dùng chỉ thấy dữ liệu của họ
- ✅ Mật khẩu được hash bởi Supabase Auth
- ✅ Row Level Security (RLS) bảo vệ tất cả bảng
- ✅ API Key được bảo vệ

## ⏰ Dữ liệu cũ (>1 năm)

Tự động xóa dữ liệu cũ:
```dart
// Gọi lần lượt (ví dụ: hàng tháng)
await provider.deleteOldRecords();
```

Hoặc cấu hình Cron job tự động trong Supabase:
- Supabase Console → Database → Extensions → pg_cron
- Tạo job chạy hàng tháng

## 🐛 Troubleshooting

| Lỗi | Giải pháp |
|-----|----------|
| "User not authenticated" | Đăng nhập trước khi lưu dữ liệu |
| "Policy violation" | Kiểm tra user đã authenticated đúng |
| Daily summary không update | Chạy lại SQL schema để tạo trigger |
| Không thấy bảng trong Database | Refresh browser hoặc chạy SQL lại |

## 📊 File mới được tạo

```
lib/
├── services/
│   └── supabase_service.dart (Kết nối Supabase)
├── providers/
│   └── supabase_provider.dart (State management)
└── screens/
    ├── login_screen.dart (Đăng nhập/Đăng ký)
    └── stats_screen.dart (Hiển thị thống kê)

supabase_schema.sql (Database schema)
SUPABASE_SETUP.md (Hướng dẫn chi tiết)
```

## ✨ Tính năng

- ✅ Đăng ký/Đăng nhập người dùng
- ✅ Lưu dữ liệu nhịp tim & SpO2 từ BLE
- ✅ Tóm tắt hàng ngày tự động
- ✅ Thống kê theo tuần/tháng/năm
- ✅ Chỉ lưu dữ liệu trong 1 năm
- ✅ Mỗi tài khoản cách ly dữ liệu
- ✅ Bảo mật với RLS

## 🎯 Bước tiếp theo

1. ✅ Import schema SQL
2. ✅ Cập nhật Flutter dependencies
3. ✅ Thêm Supabase initialization
4. ✅ Thêm Provider MultiProvider
5. ✅ Test đăng nhập
6. ✅ Test lưu dữ liệu
7. ✅ Xem thống kê

Chúc mừng! 🎉 Database của bạn đã sẵn sàng!
