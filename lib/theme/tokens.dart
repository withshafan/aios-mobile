import 'package:flutter/material.dart';

// Breakpoints
const double breakpointPhone = 600;
const double breakpointTablet = 1024;

// Device type
enum DeviceType { phone, tablet, desktop }

// Colors - Dark
class AppColors {
  static const Color bgCanvas = Color(0xFF0A0B10);
  static const Color surfaceBase = Color(0xFF12141C);
  static const Color surfaceRaised = Color(0xFF181B26);
  static const Color surfaceOverlay = Color(0xFF1E212E);
  static const Color surfaceGlass = Color(0x9E181B26); // rgba(24,27,38,0.62)
  static const Color borderHairline = Color(0x14FFFFFF); // 8% white
  static const Color borderStrong = Color(0x28FFFFFF); // 16% white
  static const Color textPrimary = Color(0xFFF2F3F7);
  static const Color textSecondary = Color(0xFFA8ACBD);
  static const Color textDisabled = Color(0xFF5C6070);

  // Accents
  static const Color accentViolet = Color(0xFF6E5BFF);
  static const Color accentCyan = Color(0xFF37D0FF);
  static const Color accentSuccess = Color(0xFF2ED9A3);
  static const Color accentWarning = Color(0xFFFFB454);
  static const Color accentCritical = Color(0xFFFF5C72);

  // Gradient stops for agents
  static const List<Color> gradientIdle = [Color(0xFF6E5BFF), Color(0xFF4FD6C0)];
  static const List<Color> gradientActive = [Color(0xFF7A6BFF), Color(0xFF37D0FF)];
  static const List<Color> gradientSuccess = [Color(0xFF2ED9A3), Color(0xFF22C3E6)];
  static const List<Color> gradientWarning = [Color(0xFFFFB454), Color(0xFFFF7A59)];
  static const List<Color> gradientCritical = [Color(0xFFFF5C72), Color(0xFFFF2E55)];
}

// Spacing
const double space1 = 4;
const double space2 = 8;
const double space3 = 12;
const double space4 = 16;
const double space5 = 20;
const double space6 = 24;
const double space7 = 32;
const double space8 = 40;
const double space9 = 48;
const double space10 = 64;
const double space11 = 80;

// Radii
const double radiusXs = 4;
const double radiusSm = 8;
const double radiusMd = 12;
const double radiusLg = 20;
const double radiusXl = 28;
const double radiusFull = 999;
