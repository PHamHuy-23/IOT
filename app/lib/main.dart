import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/health_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/family_share_provider.dart';
import 'providers/user_data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth_screen.dart'; // Đảm bảo đã import màn hình auth
import 'themes/app_theme.dart';
import 'widgets/provider_binder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['url']!,
    anonKey: dotenv.env['anonKey']!,
  );

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider), // dùng instance đã init
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => FamilyShareProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: ProviderBinder(
        child: MaterialApp(
          title: 'Health Monitor BLE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          
          // === THAY THẾ HOÀN TOÀN DÒNG "home: const DashboardScreen()," BẰNG ĐOẠN DƯỚI ĐÂY ===
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              // 1. Nếu app đang bận kiểm tra bộ nhớ lúc khởi động -> Hiện màn hình chờ
              if (auth.isLoading) {
                return const Scaffold(
                  backgroundColor: AppTheme.black,
                  body: Center(
                    child: CircularProgressIndicator(color: AppTheme.accentRed),
                  ),
                );
              }
              
              return auth.isLoggedIn
                  ? const DashboardScreen()
                  : const AuthScreen();
            },
          ),
          // =================================================================================
          
        ),
      ),
    );
  }
}
