# Hướng dẫn Tích hợp Database vào App Hiện tại

## 🔧 Bước 1: Update pubspec.yaml

```bash
flutter pub add supabase_flutter
```

Hoặc thêm thủ công vào dependencies:
```yaml
supabase_flutter: ^1.11.0
```

Sau đó chạy:
```bash
flutter pub get
```

## 🔄 Bước 2: Cập nhật main.dart

**Trước:**
```dart
void main() {
  runApp(const MyApp());
}
```

**Sau:**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (copy từ Supabase Console)
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );

  runApp(const MyApp());
}
```

## 📦 Bước 3: Thêm Providers vào MyApp

**Trước:**
```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HealthDashboardScreen(),
    );
  }
}
```

**Sau:**
```dart
import 'package:provider/provider.dart';
import 'providers/supabase_provider.dart';
import 'screens/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SupabaseProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => HealthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Health Monitor',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: Consumer<SupabaseProvider>(
          builder: (context, supabaseProvider, _) {
            // Chuyển hướng dựa trên auth status
            if (supabaseProvider.isAuthenticated) {
              return const HealthDashboardScreen();
            } else {
              return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
```

## 🔐 Bước 4: Update Health Dashboard để dùng Real Data

### Thêm import
```dart
import 'package:provider/provider.dart';
import '../providers/supabase_provider.dart';
```

### Thay thế mock data bằng real data

**Ví dụ 1: Nhịp tim**

Trước:
```dart
Consumer<HealthProvider>(
  builder: (context, provider, _) => _buildBentoCard(
    title: 'Nhịp tim',
    value: provider.isConnected ? '${provider.heartRate}' : '--',
    unit: 'BPM',
    icon: Icons.favorite_rounded,
    color: HealthColors.heartRate,
    subtitle: provider.isConnected ? 'Đang đo thực tế' : 'Chưa kết nối',
  ),
),
```

Sau:
```dart
Consumer<SupabaseProvider>(
  builder: (context, supabaseProvider, _) =>
    FutureBuilder<Map<String, dynamic>?>(
      future: supabaseProvider.getDailySummary(DateTime.now()),
      builder: (context, snapshot) {
        final avgHR = snapshot.data?['avg_heart_rate']?.toString() ?? '--';
        return _buildBentoCard(
          title: 'Nhịp tim',
          value: avgHR,
          unit: 'BPM',
          icon: Icons.favorite_rounded,
          color: HealthColors.heartRate,
          subtitle: 'Trung bình hôm nay',
        );
      },
    ),
),
```

**Ví dụ 2: Oxy trong máu**

```dart
Consumer<SupabaseProvider>(
  builder: (context, supabaseProvider, _) =>
    FutureBuilder<Map<String, dynamic>?>(
      future: supabaseProvider.getDailySummary(DateTime.now()),
      builder: (context, snapshot) {
        final avgSpo2 = snapshot.data?['avg_spo2']?.toString() ?? '--';
        return _buildBentoCard(
          title: 'Oxy trong máu',
          value: avgSpo2,
          unit: '%',
          icon: Icons.bloodtype_rounded,
          color: HealthColors.spo2,
          subtitle: 'Trung bình hôm nay',
        );
      },
    ),
),
```

## 💾 Bước 5: Tích hợp lưu dữ liệu từ BLE

### Tìm nơi bạn nhận dữ liệu từ sensor

Trong `health_provider.dart` hoặc BLE service, tìm chỗ update `heartRate` và `spO2`:

**Trước:**
```dart
setState(() {
  _heartRate = value;  // Chỉ cập nhật local
});
```

**Sau:**
```dart
final supabaseProvider = context.read<SupabaseProvider>();
final metric = HealthMetrics(
  heartRate: value,
  spO2: _spO2,
  timestamp: DateTime.now(),
);
await supabaseProvider.saveHealthMetric(metric);

setState(() {
  _heartRate = value;
});
```

## 📊 Bước 6: Thêm Stats Screen vào Navigation

### Thêm button hoặc nav bar

**Option 1: Floating Action Button**
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatsScreen()),
    );
  },
  child: const Icon(Icons.bar_chart),
),
```

**Option 2: Bottom Navigation Bar**
```dart
bottomNavigationBar: BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: 'Thống kê',
    ),
  ],
  onTap: (index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatsScreen()),
      );
    }
  },
),
```

## 🚀 Bước 7: Thêm Logout Button

Trong `HealthDashboardScreen`, thêm menu:

```dart
appBar: AppBar(
  actions: [
    PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Đăng xuất'),
          onTap: () async {
            final supabaseProvider = 
              context.read<SupabaseProvider>();
            await supabaseProvider.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
      ],
    ),
  ],
),
```

## ✅ Bước 8: Testing

### Test đăng ký
```
1. Chạy app
2. Click "Chưa có tài khoản? Đăng ký"
3. Nhập email, username, password
4. Click "Đăng ký"
5. Kiểm tra Supabase Console → Authentication
```

### Test lưu dữ liệu
```
1. Đăng nhập
2. Kết nối BLE device
3. Đợi dữ liệu từ sensor
4. Kiểm tra Supabase Console → Database → health_records
```

### Test thống kê
```
1. Mở Stats Screen
2. Click tab "Hôm nay"
3. Xem dữ liệu được tính toán từ database
4. Thử các tab khác (tuần/tháng/năm)
```

## 🔧 File cần sửa

| File | Sửa |
|------|-----|
| `main.dart` | ✅ Thêm Supabase init & providers |
| `lib/screens/health_dashboard_screen.dart` | ✅ Thay mock → real data |
| Health BLE service | ✅ Thêm `saveHealthMetric()` |
| `pubspec.yaml` | ✅ Thêm `supabase_flutter` |

## 🎯 Kết quả sau tích hợp

- ✅ Đăng nhập/Đăng ký hoạt động
- ✅ Dữ liệu lưu vào database thực
- ✅ Dashboard hiển thị dữ liệu thực từ database
- ✅ Thống kê hôm nay/tuần/tháng/năm hoạt động
- ✅ Mỗi user chỉ thấy dữ liệu riêng
- ✅ Dữ liệu cũ được tự động xóa sau 1 năm

## 💡 Tips

1. **Hot reload**: Sau khi sửa code, hot reload sẽ không khởi tạo lại Supabase, nên cần hot restart nếu có lỗi connection
   ```bash
   flutter run --no-fast-start
   ```

2. **Debugging**: Thêm prints để debug
   ```dart
   print('Saving metric: $metric');
   await supabaseProvider.saveHealthMetric(metric);
   print('Metric saved!');
   ```

3. **Error handling**: Luôn check `supabaseProvider.errorMessage`
   ```dart
   if (supabaseProvider.errorMessage != null) {
     print('Error: ${supabaseProvider.errorMessage}');
   }
   ```

4. **Performance**: Không query quá nhiều dữ liệu
   ```dart
   // ✅ Tốt: Query chỉ hôm nay
   await supabaseProvider.getTodayMetrics();
   
   // ❌ Xấu: Query toàn bộ 1 năm
   await supabaseProvider.getMetricsByDateRange(
     DateTime.now().subtract(Duration(days: 365)),
     DateTime.now(),
   );
   ```

---

**Bạn đã sẵn sàng để integrate! Chúc mừng!** 🎉
