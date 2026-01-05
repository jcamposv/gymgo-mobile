import 'package:flutter/material.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';

/// GymGo page header with title and subtitle
class GymGoHeader extends StatelessWidget {
  const GymGoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.alignment = CrossAxisAlignment.start,
    this.showLogo = false,
    this.logoWidget,
  });

  final String title;
  final String? subtitle;
  final CrossAxisAlignment alignment;
  final bool showLogo;
  final Widget? logoWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (showLogo) ...[
          logoWidget ?? const _GymGoLogo(),
          const SizedBox(height: GymGoSpacing.xl),
        ],
        Text(
          title,
          style: GymGoTypography.displaySmall,
          textAlign: _getTextAlign(),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            subtitle!,
            style: GymGoTypography.bodyLarge.copyWith(
              color: GymGoColors.textSecondary,
            ),
            textAlign: _getTextAlign(),
          ),
        ],
      ],
    );
  }

  TextAlign _getTextAlign() {
    switch (alignment) {
      case CrossAxisAlignment.center:
        return TextAlign.center;
      case CrossAxisAlignment.end:
        return TextAlign.end;
      default:
        return TextAlign.start;
    }
  }
}

/// GymGo logo placeholder
class _GymGoLogo extends StatelessWidget {
  const _GymGoLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.lg,
        vertical: GymGoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.primary,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Text(
        'GYMGO',
        style: GymGoTypography.headlineLarge.copyWith(
          color: GymGoColors.background,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// Reusable GymGo logo widget
class GymGoLogo extends StatelessWidget {
  const GymGoLogo({
    super.key,
    this.size = GymGoLogoSize.medium,
    this.showText = true,
  });

  final GymGoLogoSize size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final (fontSize, padding) = _getSize();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: GymGoColors.primary,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: showText
          ? Text(
              'GYMGO',
              style: TextStyle(
                fontFamily: GymGoTypography.fontFamily,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: GymGoColors.background,
                letterSpacing: 2,
              ),
            )
          : Icon(
              Icons.fitness_center,
              size: fontSize,
              color: GymGoColors.background,
            ),
    );
  }

  (double, EdgeInsetsGeometry) _getSize() {
    switch (size) {
      case GymGoLogoSize.small:
        return (16.0, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
      case GymGoLogoSize.medium:
        return (24.0, const EdgeInsets.symmetric(horizontal: 20, vertical: 12));
      case GymGoLogoSize.large:
        return (32.0, const EdgeInsets.symmetric(horizontal: 28, vertical: 16));
    }
  }
}

enum GymGoLogoSize { small, medium, large }
