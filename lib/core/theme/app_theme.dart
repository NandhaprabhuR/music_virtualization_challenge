import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color accent = Color(0xFFE53935); // Red accent
  static const Color accentLight = Color(0xFFFF5252);

  // Dark mode colors
  static const Color darkBg = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1C1C1C);
  static const Color darkText = Colors.white;
  static const Color darkSubtext = Color(0xFF9E9E9E);

  // Light mode colors
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightSubtext = Color(0xFF757575);

  static TextTheme _buildTextTheme(TextTheme base) {
    return base;
  }

  static ThemeData darkTheme() {
    final base = ThemeData.dark();
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: darkSurface,
        onSurface: darkText,
        onPrimary: Colors.white,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: darkText),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: lightSurface,
        onSurface: lightText,
        onPrimary: Colors.white,
      ),
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: lightText),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Extension helpers to get theme-aware colors easily
extension AppColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get accent => AppTheme.accent;
  Color get bg => isDark ? AppTheme.darkBg : AppTheme.lightBg;
  Color get surface => isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
  Color get card => isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get textPrimary => isDark ? AppTheme.darkText : AppTheme.lightText;
  Color get textSecondary =>
      isDark ? AppTheme.darkSubtext : AppTheme.lightSubtext;
  Color get dividerColor => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);
}
