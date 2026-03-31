import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF075E54);
  static const Color primaryLight = Color(0xFF25D366);
  static const Color secondary = Color(0xFF128C7E);
  static const Color bubbleMe = Color(0xFFDCF8C6);
  static const Color bubbleOther = Colors.white;
  static const Color background = Color(0xFFECE5DD);
  static const Color appBar = Color(0xFF075E54);

  // Level indicator colors
  static const Color level1Color = Color(0xFF4CAF50);
  static const Color level2Color = Color(0xFF2196F3);
  static const Color level3Color = Color(0xFF9C27B0);

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }
}
