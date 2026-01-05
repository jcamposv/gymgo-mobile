import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';

/// GymGo primary button with lime accent
class GymGoPrimaryButton extends StatelessWidget {
  const GymGoPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = 56,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? GymGoColors.primary.withValues(alpha: 0.5)
              : GymGoColors.primary,
          foregroundColor: GymGoColors.background,
          disabledBackgroundColor: GymGoColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: GymGoColors.background.withValues(alpha: 0.7),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.buttonHorizontal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      GymGoColors.background.withValues(alpha: 0.8),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: GymGoSpacing.iconMd,
                      ),
                      const SizedBox(width: GymGoSpacing.xs),
                    ],
                    Text(
                      text,
                      style: GymGoTypography.buttonLarge.copyWith(
                        color: isDisabled
                            ? GymGoColors.background.withValues(alpha: 0.7)
                            : GymGoColors.background,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ).animate(target: isDisabled ? 0 : 1).scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 100.ms,
        );
  }
}

/// GymGo secondary/outlined button
class GymGoSecondaryButton extends StatelessWidget {
  const GymGoSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height = 56,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textPrimary,
          disabledForegroundColor: GymGoColors.textDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.buttonHorizontal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
          side: BorderSide(
            color: isDisabled ? GymGoColors.textDisabled : GymGoColors.inputBorder,
            width: 1,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      GymGoColors.textSecondary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: GymGoSpacing.iconMd,
                      ),
                      const SizedBox(width: GymGoSpacing.xs),
                    ],
                    Text(
                      text,
                      style: GymGoTypography.buttonLarge,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// GymGo text/link button
class GymGoTextButton extends StatelessWidget {
  const GymGoTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.icon,
    this.color,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? GymGoColors.primary;

    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        disabledForegroundColor: GymGoColors.textDisabled,
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.sm,
          vertical: GymGoSpacing.xs,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: GymGoSpacing.iconSm,
            ),
            const SizedBox(width: GymGoSpacing.xxs),
          ],
          Text(
            text,
            style: GymGoTypography.buttonMedium.copyWith(
              color: isEnabled ? textColor : GymGoColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
