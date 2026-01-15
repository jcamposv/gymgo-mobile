import 'package:flutter/material.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';

/// GymGo styled card with dark theme
class GymGoCard extends StatelessWidget {
  const GymGoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? GymGoSpacing.radiusLg),
        border: Border.all(
          color: borderColor ?? GymGoColors.cardBorder,
          width: 1,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(GymGoSpacing.cardPadding),
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius ?? GymGoSpacing.radiusLg),
        child: card,
      );
    }

    return card;
  }
}

/// GymGo gradient card for featured content
class GymGoGradientCard extends StatelessWidget {
  const GymGoGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? GymGoColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? GymGoSpacing.radiusLg),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(GymGoSpacing.cardPadding),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? GymGoSpacing.radiusLg),
        child: card,
      );
    }

    return card;
  }
}
