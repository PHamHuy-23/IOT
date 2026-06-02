import 'package:flutter/material.dart';

class AppTheme {
  // Dark Mode - Medical/Fitness Dashboard Colors
  static const Color deepObsidian = Color(0xFF0B0E1B);
  static const Color darkSlate = Color(0xFF1A1F3A);
  static const Color neonCyan = Color(0xFF00D9FF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color electricRed = Color(0xFFFF1744);
  static const Color electricPink = Color(0xFFFF4081);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color softWhite = Color(0xFFE8E8E8);
  static const Color mutedGrey = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepObsidian,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSlate,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: softWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSlate,
        elevation: 8,
        shadowColor: neonCyan.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: neonCyan,
            width: 0.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: softWhite,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: accentPurple.withOpacity(0.4),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: softWhite,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: softWhite,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: softWhite,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: softWhite,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: mutedGrey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: TextStyle(
          color: mutedGrey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: neonCyan,
        tertiary: neonGreen,
        surface: darkSlate,
        background: deepObsidian,
        error: electricRed,
      ),
    );
  }

  // Color getters for easy access
  static Color getHeartRateColor(int bpm) {
    if (bpm == 0) return mutedGrey;
    if (bpm < 60) return neonCyan;
    if (bpm < 100) return neonGreen;
    if (bpm < 130) return Colors.orange.shade400;
    return electricRed;
  }

  static Color getSpO2Color(int spo2) {
    if (spo2 == 0) return mutedGrey;
    if (spo2 >= 95) return neonGreen;
    if (spo2 >= 90) return neonCyan;
    if (spo2 >= 85) return Colors.orange.shade400;
    return electricRed;
  }
}
