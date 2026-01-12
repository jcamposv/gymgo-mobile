import 'package:flutter/material.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';

/// Fallback widget for profile photo when no image is available
/// Shows a gradient background with the member's initials
class PhotoFallback extends StatelessWidget {
  const PhotoFallback({
    super.key,
    required this.initials,
    this.size = 72,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  /// Initials to display (1-2 characters)
  final String initials;

  /// Size of the fallback container
  final double size;

  /// Border radius (defaults to radiusLg for rounded square)
  final BorderRadius? borderRadius;

  /// Optional gradient (defaults to primaryGradient)
  final Gradient? gradient;

  /// Background color if not using gradient
  final Color? backgroundColor;

  /// Text color for initials (defaults based on background)
  final Color? textColor;

  /// Font size (defaults based on container size)
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(GymGoSpacing.radiusLg);

    final effectiveFontSize = fontSize ?? (size * 0.4);

    final effectiveTextColor = textColor ?? GymGoColors.background;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? GymGoColors.primaryGradient,
        color: gradient == null ? backgroundColor : null,
        borderRadius: effectiveBorderRadius,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Factory for circular fallback
  factory PhotoFallback.circular({
    Key? key,
    required String initials,
    double size = 72,
    Gradient? gradient,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
  }) {
    return PhotoFallback(
      key: key,
      initials: initials,
      size: size,
      borderRadius: BorderRadius.circular(size / 2),
      gradient: gradient,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }

  /// Factory for small size (40px)
  factory PhotoFallback.small({
    Key? key,
    required String initials,
    BorderRadius? borderRadius,
    Gradient? gradient,
  }) {
    return PhotoFallback(
      key: key,
      initials: initials,
      size: 40,
      fontSize: 14,
      borderRadius: borderRadius ?? BorderRadius.circular(GymGoSpacing.radiusMd),
      gradient: gradient,
    );
  }

  /// Factory for medium size (56px)
  factory PhotoFallback.medium({
    Key? key,
    required String initials,
    BorderRadius? borderRadius,
    Gradient? gradient,
  }) {
    return PhotoFallback(
      key: key,
      initials: initials,
      size: 56,
      fontSize: 20,
      borderRadius: borderRadius ?? BorderRadius.circular(GymGoSpacing.radiusMd),
      gradient: gradient,
    );
  }

  /// Factory for large size (80px)
  factory PhotoFallback.large({
    Key? key,
    required String initials,
    BorderRadius? borderRadius,
    Gradient? gradient,
  }) {
    return PhotoFallback(
      key: key,
      initials: initials,
      size: 80,
      fontSize: 28,
      borderRadius: borderRadius ?? BorderRadius.circular(GymGoSpacing.radiusLg),
      gradient: gradient,
    );
  }
}
