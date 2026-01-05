import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';

/// Toast/Snackbar types
enum GymGoToastType {
  success,
  error,
  warning,
  info,
}

/// GymGo styled toast/snackbar helper
class GymGoToast {
  GymGoToast._();

  /// Show a toast message
  static void show(
    BuildContext context, {
    required String message,
    GymGoToastType type = GymGoToastType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    final (icon, color, bgColor) = _getToastStyle(type);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              size: GymGoSpacing.iconMd,
              color: color,
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(GymGoSpacing.md),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: color,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show success toast
  static void success(BuildContext context, String message) {
    show(context, message: message, type: GymGoToastType.success);
  }

  /// Show error toast
  static void error(BuildContext context, String message) {
    show(context, message: message, type: GymGoToastType.error);
  }

  /// Show warning toast
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: GymGoToastType.warning);
  }

  /// Show info toast
  static void info(BuildContext context, String message) {
    show(context, message: message, type: GymGoToastType.info);
  }

  static (IconData, Color, Color) _getToastStyle(GymGoToastType type) {
    switch (type) {
      case GymGoToastType.success:
        return (
          LucideIcons.checkCircle,
          GymGoColors.success,
          GymGoColors.surfaceElevated,
        );
      case GymGoToastType.error:
        return (
          LucideIcons.xCircle,
          GymGoColors.error,
          GymGoColors.surfaceElevated,
        );
      case GymGoToastType.warning:
        return (
          LucideIcons.alertTriangle,
          GymGoColors.warning,
          GymGoColors.surfaceElevated,
        );
      case GymGoToastType.info:
        return (
          LucideIcons.info,
          GymGoColors.info,
          GymGoColors.surfaceElevated,
        );
    }
  }
}
