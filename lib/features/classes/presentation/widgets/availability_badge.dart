import 'package:flutter/material.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Badge showing available spots with color-coded status
class AvailabilityBadge extends StatelessWidget {
  const AvailabilityBadge({
    super.key,
    required this.available,
    required this.capacity,
    this.showIcon = false,
    this.compact = false,
  });

  final int available;
  final int capacity;
  final bool showIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isFull = available <= 0;
    final isAlmostFull = available > 0 && available <= 3;

    final Color bgColor;
    final Color textColor;

    if (isFull) {
      bgColor = GymGoColors.error.withValues(alpha: 0.15);
      textColor = GymGoColors.error;
    } else if (isAlmostFull) {
      bgColor = GymGoColors.warning.withValues(alpha: 0.15);
      textColor = GymGoColors.warning;
    } else {
      bgColor = GymGoColors.success.withValues(alpha: 0.15);
      textColor = GymGoColors.success;
    }

    final String text;
    if (isFull) {
      text = 'Lleno';
    } else if (compact) {
      text = '$available ${available == 1 ? 'cupo' : 'cupos'}';
    } else {
      text = '$available ${available == 1 ? 'cupo disponible' : 'cupos disponibles'}';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? GymGoSpacing.xs : GymGoSpacing.sm,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              isFull ? Icons.block : Icons.person_add_outlined,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: (compact ? GymGoTypography.labelSmall : GymGoTypography.labelMedium).copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text-only availability indicator (simpler version)
class AvailabilityText extends StatelessWidget {
  const AvailabilityText({
    super.key,
    required this.available,
    required this.capacity,
    this.style,
  });

  final int available;
  final int capacity;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isFull = available <= 0;
    final isAlmostFull = available > 0 && available <= 3;

    final Color textColor;
    if (isFull) {
      textColor = GymGoColors.error;
    } else if (isAlmostFull) {
      textColor = GymGoColors.warning;
    } else {
      textColor = GymGoColors.success;
    }

    final String text;
    if (isFull) {
      text = 'Sin cupos';
    } else {
      text = '$available ${available == 1 ? 'cupo disponible' : 'cupos disponibles'}';
    }

    return Text(
      text,
      style: (style ?? GymGoTypography.labelMedium).copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Capacity progress indicator with visual bar
class CapacityIndicator extends StatelessWidget {
  const CapacityIndicator({
    super.key,
    required this.enrolled,
    required this.capacity,
    this.height = 4.0,
    this.showText = true,
  });

  final int enrolled;
  final int capacity;
  final double height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final available = capacity - enrolled;
    final isFull = available <= 0;
    final isAlmostFull = available > 0 && available <= 3;
    final progress = capacity > 0 ? enrolled / capacity : 0.0;

    final Color progressColor;
    if (isFull) {
      progressColor = GymGoColors.error;
    } else if (isAlmostFull) {
      progressColor = GymGoColors.warning;
    } else {
      progressColor = GymGoColors.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$enrolled/$capacity inscritos',
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
              AvailabilityBadge(
                available: available,
                capacity: capacity,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: GymGoColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}
