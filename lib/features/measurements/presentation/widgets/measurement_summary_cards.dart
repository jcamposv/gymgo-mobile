import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/measurement.dart';

/// Summary cards showing key metrics from the latest measurement
class MeasurementSummaryCards extends StatelessWidget {
  const MeasurementSummaryCards({
    super.key,
    required this.latestMeasurement,
    this.previousMeasurement,
  });

  final Measurement latestMeasurement;
  final Measurement? previousMeasurement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary metrics row (Weight and Body Fat)
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.scale,
                label: 'Peso',
                value: latestMeasurement.bodyWeightKg,
                unit: 'kg',
                previousValue: previousMeasurement?.bodyWeightKg,
                color: const Color(0xFF84cc16), // Lime
                invertDelta: true, // Weight decrease is good
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.percent,
                label: 'Grasa corporal',
                value: latestMeasurement.bodyFatPercentage,
                unit: '%',
                previousValue: previousMeasurement?.bodyFatPercentage,
                color: const Color(0xFFf97316), // Orange
                invertDelta: true, // Fat decrease is good
              ),
            ),
          ],
        ),
        const SizedBox(height: GymGoSpacing.md),

        // Secondary metrics row (Muscle Mass and BMI)
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.dumbbell,
                label: 'Masa muscular',
                value: latestMeasurement.muscleMassKg,
                unit: 'kg',
                previousValue: previousMeasurement?.muscleMassKg,
                color: const Color(0xFF3b82f6), // Blue
                invertDelta: false, // Muscle increase is good
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: _MetricCard(
                icon: LucideIcons.activity,
                label: 'IMC',
                value: latestMeasurement.calculatedBmi,
                unit: '',
                previousValue: previousMeasurement?.calculatedBmi,
                color: const Color(0xFF8b5cf6), // Violet
                invertDelta: true,
                subtitle: latestMeasurement.bmiCategory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.previousValue,
    this.invertDelta = false,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final double? value;
  final String unit;
  final Color color;
  final double? previousValue;
  final bool invertDelta;
  final String? subtitle;

  double? get delta {
    if (value == null || previousValue == null) return null;
    return value! - previousValue!;
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Text(
                label,
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Value
          if (hasValue) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value!.toStringAsFixed(1),
                  style: GymGoTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Subtitle (e.g., BMI category)
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: GymGoTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Delta indicator
            if (delta != null) ...[
              const SizedBox(height: GymGoSpacing.sm),
              _DeltaIndicator(
                delta: delta!,
                unit: unit,
                invertColors: invertDelta,
              ),
            ],
          ] else
            Text(
              '---',
              style: GymGoTypography.headlineMedium.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DeltaIndicator extends StatelessWidget {
  const _DeltaIndicator({
    required this.delta,
    required this.unit,
    this.invertColors = false,
  });

  final double delta;
  final String unit;
  final bool invertColors;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta > 0;
    final isNeutral = delta.abs() < 0.1;

    // Determine color based on whether positive is good or bad
    Color color;
    if (isNeutral) {
      color = GymGoColors.textTertiary;
    } else if (invertColors) {
      color = isPositive ? GymGoColors.error : GymGoColors.success;
    } else {
      color = isPositive ? GymGoColors.success : GymGoColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNeutral)
            Icon(
              isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 12,
              color: color,
            ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}${unit.isNotEmpty ? ' $unit' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
