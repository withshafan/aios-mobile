import 'package:flutter/material.dart';
import 'aura_theme.dart'; // ← add this

class NovaColors {
  static const lightBg = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF5F5F7);
  static const lightText = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF8E8E93);
  static const lightBorder = Color(0xFFE5E5EA);

  static const darkBg = Color(0xFF0A0B10);
  static const darkSurface = Color(0xFF12141C);
  static const darkSurface2 = Color(0xFF181B26);
  static const darkText = Color(0xFFF2F3F7);
  static const darkTextSecondary = Color(0xFFA8ACBD);
  static const darkBorder = Color(0xFF20232E);

  static const accent = Color(0xFF7C5CFC);
  static const accentLight = Color(0xFFA78BFA);
  static const accentGradientStart = Color(0xFF7C5CFC);
  static const accentGradientEnd = Color(0xFF4FD6C0);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFF87171);
}

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: NovaColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: NovaColors.accent,
      secondary: NovaColors.accentLight,
      surface: NovaColors.lightSurface,
      error: NovaColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NovaColors.lightBg,
      foregroundColor: NovaColors.lightText,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: NovaColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NovaColors.lightBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NovaColors.lightSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    extensions: [AuraTheme.dark()], // ← add
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NovaColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: NovaColors.accent,
      secondary: NovaColors.accentLight,
      surface: NovaColors.darkSurface,
      error: NovaColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: NovaColors.darkBg,
      foregroundColor: NovaColors.darkText,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: NovaColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: NovaColors.darkBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NovaColors.darkSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    extensions: [AuraTheme.dark()], // ← add
  );
}
