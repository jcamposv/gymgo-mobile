import 'package:flutter/material.dart';

/// GymGo Color Palette
/// Premium fitness dark theme with lime accents
class GymGoColors {
  GymGoColors._();

  // Primary - Lime/Green accent
  static const Color primary = Color(0xFFCDFF00);
  static const Color primaryDark = Color(0xFFB8E600);
  static const Color primaryLight = Color(0xFFE5FF66);

  // Background colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundSecondary = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF242424);
  static const Color surfaceElevated = Color(0xFF2A2A2A);

  // Card colors
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color cardBorder = Color(0xFF2E2E2E);
  static const Color cardHover = Color(0xFF252525);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF4D4D4D);

  // Input colors
  static const Color inputBackground = Color(0xFF1A1A1A);
  static const Color inputBorder = Color(0xFF333333);
  static const Color inputBorderFocus = primary;
  static const Color inputPlaceholder = Color(0xFF666666);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFE57373);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);

  // Gradient for premium effects
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardBackground, surface],
  );

  // Overlay colors
  static const Color overlayDark = Color(0xCC000000);
  static const Color overlayLight = Color(0x33FFFFFF);

  // Divider
  static const Color divider = Color(0xFF2E2E2E);

  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFF1E1E1E);
  static const Color shimmerHighlight = Color(0xFF2E2E2E);
}
