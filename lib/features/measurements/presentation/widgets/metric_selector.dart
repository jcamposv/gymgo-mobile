import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/measurement.dart';

/// Horizontal selector for choosing which metric to display in the chart
class MetricSelector extends StatelessWidget {
  const MetricSelector({
    super.key,
    required this.selectedMetric,
    required this.onMetricSelected,
  });

  final MetricType selectedMetric;
  final void Function(MetricType) onMetricSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MetricType.values.map((metric) {
          final isSelected = metric == selectedMetric;
          return Padding(
            padding: EdgeInsets.only(
              right: metric != MetricType.values.last ? GymGoSpacing.sm : 0,
            ),
            child: _MetricChip(
              metric: metric,
              isSelected: isSelected,
              onTap: () => onMetricSelected(metric),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.metric,
    required this.isSelected,
    required this.onTap,
  });

  final MetricType metric;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (metric) {
      case MetricType.weight:
        return LucideIcons.scale;
      case MetricType.bodyFat:
        return LucideIcons.percent;
      case MetricType.muscleMass:
        return LucideIcons.dumbbell;
      case MetricType.bmi:
        return LucideIcons.activity;
    }
  }

  Color get _color {
    switch (metric) {
      case MetricType.weight:
        return const Color(0xFF84cc16); // Lime
      case MetricType.bodyFat:
        return const Color(0xFFf97316); // Orange
      case MetricType.muscleMass:
        return const Color(0xFF3b82f6); // Blue
      case MetricType.bmi:
        return const Color(0xFF8b5cf6); // Violet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? _color.withValues(alpha: 0.15) : GymGoColors.surfaceLight,
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
            border: Border.all(
              color: isSelected ? _color : GymGoColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                size: 16,
                color: isSelected ? _color : GymGoColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                metric.label,
                style: GymGoTypography.labelSmall.copyWith(
                  color: isSelected ? _color : GymGoColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
