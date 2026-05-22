import 'package:flutter/material.dart';

class AppColors {
  // Cores principais (lavanda/roxo suave - acolhedor)
  static const Color primary = Color(0xFF9B87F5);
  static const Color primaryDark = Color(0xFF7C6FE0);
  static const Color primaryLight = Color(0xFFE5DEFF);

  // Cores secundárias
  static const Color accent = Color(0xFFFFB4A2);
  static const Color success = Color(0xFF95D5B2);
  static const Color warning = Color(0xFFFFD6A5);

  // Neutros
  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF6B6B7B);
  static const Color textHint = Color(0xFFA5A5B5);

  // Estados
  static const Color error = Color(0xFFE57373);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}