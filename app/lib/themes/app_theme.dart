import 'package:flutter/material.dart';

class AppTheme {
  // ===== Màu nền =====
  static const Color black = Color(0xFF000000);
  static const Color cardDark = Color(0xFF1C1C1E);
  static const Color cardDarker = Color(0xFF2C2C2E);

  // ===== Màu accent =====
  static const Color accentRed = Color(0xFFFF2D55);    // Nhịp tim / Tab active
  static const Color electricRed = Color(0xFFFF1744);  // High-alert / electric red (IMPLEMENTATION_GUIDE)
  static const Color accentBlue = Color(0xFF007AFF);   // Nước uống
  static const Color accentGreen = Color(0xFF34C759);  // Bước chân
  static const Color accentOrange = Color(0xFFFF9500); // Năng lượng
  static const Color accentPurple = Color(0xFFAF52DE); // Giấc ngủ
  static const Color accentTeal = Color(0xFF00C7B7);   // SpO2 / Chánh niệm
  static const Color neonGreen = Color(0xFF30D158);    // Trạng thái kết nối

  // ===== Màu chữ =====
  static const Color softWhite = Color(0xFFFFFFFF);
  static const Color mutedGrey = Color(0xFF8E8E93);
  static const Color subtleGrey = Color(0xFF3A3A3C);

  // ===== Helper: màu theo nhịp tim =====
  static Color getHeartRateColor(int hr) {
    if (hr == 0) return mutedGrey;
    if (hr < 60) return accentBlue;
    if (hr <= 100) return accentRed;
    return const Color(0xFFFF6B6B);
  }

  // ===== Helper: màu theo SpO2 =====
  static Color getSpO2Color(int spo2) {
    if (spo2 == 0) return mutedGrey;
    if (spo2 >= 95) return accentTeal;
    if (spo2 >= 90) return accentOrange;
    return accentRed;
  }

  // ===== ThemeData toàn app =====
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: black,
        colorScheme: const ColorScheme.dark(
          primary: accentRed,
          secondary: accentPurple,
          surface: cardDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: softWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: softWhite),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1C1E),
          selectedItemColor: accentRed,
          unselectedItemColor: mutedGrey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: softWhite),
          bodySmall: TextStyle(color: mutedGrey),
        ),
      );
}