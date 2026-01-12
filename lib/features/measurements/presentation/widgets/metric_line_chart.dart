import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/measurement.dart';

/// Line chart showing measurement progress over time
/// Data should be sorted ascending by date (oldest first)
class MetricLineChart extends StatelessWidget {
  const MetricLineChart({
    super.key,
    required this.measurements,
    required this.metricType,
  });

  final List<Measurement> measurements;
  final MetricType metricType;

  Color get _chartColor {
    switch (metricType) {
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
    // Filter measurements that have data for this metric
    final validMeasurements = measurements
        .where((m) => metricType.getValue(m) != null)
        .toList();

    if (validMeasurements.isEmpty) {
      return _buildEmptyState();
    }

    if (validMeasurements.length < 2) {
      return _buildInsufficientDataState();
    }

    // Calculate delta for motivation
    final firstValue = metricType.getValue(validMeasurements.first);
    final lastValue = metricType.getValue(validMeasurements.last);
    final delta = lastValue != null && firstValue != null
        ? lastValue - firstValue
        : null;

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delta indicator
          if (delta != null) _buildDeltaIndicator(delta, validMeasurements),

          const SizedBox(height: GymGoSpacing.md),

          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              _buildChartData(validMeasurements),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.xl),
      child: Column(
        children: [
          Icon(
            LucideIcons.lineChart,
            color: GymGoColors.textTertiary,
            size: 48,
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Sin datos de ${metricType.label.toLowerCase()}',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            'Agrega mediciones para ver tu progreso',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataState() {
    final measurement = measurements.firstWhere(
      (m) => metricType.getValue(m) != null,
      orElse: () => measurements.first,
    );
    final value = metricType.getValue(measurement);

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _chartColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.target,
                  color: _chartColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valor actual',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value?.toStringAsFixed(1) ?? '---',
                          style: GymGoTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (metricType.unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              metricType.unit,
                              style: GymGoTypography.bodySmall.copyWith(
                                color: GymGoColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GymGoSpacing.md),
            decoration: BoxDecoration(
              color: GymGoColors.surfaceLight,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  color: GymGoColors.info,
                  size: 16,
                ),
                const SizedBox(width: GymGoSpacing.sm),
                Expanded(
                  child: Text(
                    'Necesitas al menos 2 mediciones para ver el gráfico',
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaIndicator(double delta, List<Measurement> data) {
    final isPositive = delta > 0;
    final isNeutral = delta.abs() < 0.1;

    // Determine if positive is good based on metric
    final bool invertColors = metricType == MetricType.weight ||
        metricType == MetricType.bodyFat ||
        metricType == MetricType.bmi;

    Color color;
    if (isNeutral) {
      color = GymGoColors.textTertiary;
    } else if (invertColors) {
      color = isPositive ? GymGoColors.error : GymGoColors.success;
    } else {
      color = isPositive ? GymGoColors.success : GymGoColors.error;
    }

    // Calculate time span
    final firstDate = data.first.measuredAt;
    final lastDate = data.last.measuredAt;
    final days = lastDate.difference(firstDate).inDays;
    final timeSpan = days == 0
        ? 'hoy'
        : days == 1
            ? '1 día'
            : days < 30
                ? '$days días'
                : days < 60
                    ? '1 mes'
                    : '${(days / 30).round()} meses';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isNeutral)
                Icon(
                  isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  size: 16,
                  color: color,
                ),
              const SizedBox(width: 6),
              Text(
                '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)} ${metricType.unit}',
                style: GymGoTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          'en $timeSpan',
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.textTertiary,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<Measurement> data) {
    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < data.length; i++) {
      final value = metricType.getValue(data[i]);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }
    }

    // Add padding to Y axis
    final yPadding = (maxY - minY) * 0.1;
    if (yPadding > 0) {
      minY -= yPadding;
      maxY += yPadding;
    } else {
      minY -= 1;
      maxY += 1;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY - minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: GymGoColors.cardBorder.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: (maxY - minY) / 4,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textTertiary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: data.length > 7 ? (data.length / 5).ceil().toDouble() : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) return const SizedBox();

              final date = data[index].measuredAt;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.day}/${date.month}',
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: _chartColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: _chartColor,
                strokeWidth: 2,
                strokeColor: GymGoColors.cardBackground,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _chartColor.withValues(alpha: 0.3),
                _chartColor.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => GymGoColors.surfaceElevated,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final date = data[index].measuredAt;
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} ${metricType.unit}\n',
                GymGoTypography.bodySmall.copyWith(
                  color: _chartColor,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '${date.day}/${date.month}/${date.year}',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
