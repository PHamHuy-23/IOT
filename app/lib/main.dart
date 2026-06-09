import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/health_provider.dart';
import 'providers/family_share_provider.dart';
import 'providers/user_data_provider.dart';
import 'screens/dashboard_screen.dart';
import 'themes/app_theme.dart';
import 'widgets/provider_binder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ilpgcwhhtozmyfqlgetj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlscGdjd2hodG96bXlmcWxnZXRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4NjEzNTcsImV4cCI6MjA5NjQzNzM1N30.CbXpSZVm1GeOLom0iPbNVh4SPtlPAqDhe2aZKhgUt9E',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => FamilyShareProvider()),
      ],
      child: ProviderBinder(
        child: MaterialApp(
          title: 'Health Monitor BLE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}