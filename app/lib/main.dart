import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/health_provider.dart';
import 'screens/dashboard_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: MaterialApp(
        title: 'Health Monitor BLE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}