import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gymgo_colors.dart';
import 'gymgo_typography.dart';
import 'gymgo_spacing.dart';

/// GymGo Theme Configuration
/// Centralized theme for consistent styling across the app
class GymGoTheme {
  GymGoTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GymGoTypography.fontFamily,

      // Colors
      colorScheme: const ColorScheme.dark(
        primary: GymGoColors.primary,
        onPrimary: GymGoColors.background,
        secondary: GymGoColors.primaryLight,
        onSecondary: GymGoColors.background,
        surface: GymGoColors.surface,
        onSurface: GymGoColors.textPrimary,
        error: GymGoColors.error,
        onError: GymGoColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: GymGoColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: GymGoColors.background,
        foregroundColor: GymGoColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GymGoTypography.headlineMedium,
        iconTheme: IconThemeData(
          color: GymGoColors.textPrimary,
          size: GymGoSpacing.iconLg,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: GymGoColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
          side: const BorderSide(
            color: GymGoColors.cardBorder,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GymGoColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.inputHorizontal,
          vertical: GymGoSpacing.inputVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(
            color: GymGoColors.inputBorder,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(
            color: GymGoColors.inputBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(
            color: GymGoColors.inputBorderFocus,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(
            color: GymGoColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          borderSide: const BorderSide(
            color: GymGoColors.error,
            width: 2,
          ),
        ),
        hintStyle: GymGoTypography.inputHint,
        errorStyle: GymGoTypography.inputError,
        labelStyle: GymGoTypography.labelMedium,
        floatingLabelStyle: GymGoTypography.labelSmall.copyWith(
          color: GymGoColors.primary,
        ),
      ),

      // Elevated Button (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GymGoColors.primary,
          foregroundColor: GymGoColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.buttonHorizontal,
            vertical: GymGoSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
          textStyle: GymGoTypography.buttonLarge,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.buttonHorizontal,
            vertical: GymGoSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
          side: const BorderSide(
            color: GymGoColors.inputBorder,
            width: 1,
          ),
          textStyle: GymGoTypography.buttonLarge,
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GymGoColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.xs,
          ),
          textStyle: GymGoTypography.buttonMedium,
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: GymGoColors.textPrimary,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: GymGoColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GymGoColors.surfaceElevated,
        contentTextStyle: GymGoTypography.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GymGoColors.primary,
        circularTrackColor: GymGoColors.inputBorder,
        linearTrackColor: GymGoColors.inputBorder,
      ),

      // Text Selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: GymGoColors.primary,
        selectionColor: GymGoColors.primaryLight,
        selectionHandleColor: GymGoColors.primary,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: GymGoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusXl),
        ),
        titleTextStyle: GymGoTypography.headlineSmall,
        contentTextStyle: GymGoTypography.bodyMedium,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: GymGoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GymGoSpacing.radiusXl),
          ),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: GymGoTypography.displayLarge,
        displayMedium: GymGoTypography.displayMedium,
        displaySmall: GymGoTypography.displaySmall,
        headlineLarge: GymGoTypography.headlineLarge,
        headlineMedium: GymGoTypography.headlineMedium,
        headlineSmall: GymGoTypography.headlineSmall,
        titleLarge: GymGoTypography.titleLarge,
        titleMedium: GymGoTypography.titleMedium,
        titleSmall: GymGoTypography.titleSmall,
        bodyLarge: GymGoTypography.bodyLarge,
        bodyMedium: GymGoTypography.bodyMedium,
        bodySmall: GymGoTypography.bodySmall,
        labelLarge: GymGoTypography.labelLarge,
        labelMedium: GymGoTypography.labelMedium,
        labelSmall: GymGoTypography.labelSmall,
      ),
    );
  }
}
