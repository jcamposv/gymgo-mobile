import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';

/// Line chart widget for displaying PR progress over time
class PRLineChart extends StatelessWidget {
  const PRLineChart({
    super.key,
    required this.data,
    required this.unit,
  });

  final List<BenchmarkChartPoint> data;
  final BenchmarkUnit unit;

  String _formatDateShort(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatValue(double value) {
    if (unit == BenchmarkUnit.seconds && value >= 60) {
      final mins = (value / 60).floor();
      final secs = (value % 60).round();
      return '${mins}:${secs.toString().padLeft(2, '0')}';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prepare data points
    final spots = <FlSpot>[];
    final prSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final spot = FlSpot(i.toDouble(), point.value);
      spots.add(spot);
      if (point.isPr) {
        prSpots.add(spot);
      }
    }

    // Calculate min/max for Y axis
    final values = data.map((d) => d.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.1;
    final yMin = (minValue - padding).clamp(0.0, double.infinity);
    final yMax = maxValue + padding;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yMax - yMin) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: GymGoColors.cardBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatValue(value),
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateBottomInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDateShort(data[index].date),
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          // Main line
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: GymGoColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isPrPoint = data[index].isPr;
                return FlDotCirclePainter(
                  radius: isPrPoint ? 6 : 4,
                  color: isPrPoint ? GymGoColors.warning : GymGoColors.primary,
                  strokeWidth: isPrPoint ? 2 : 0,
                  strokeColor: GymGoColors.background,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GymGoColors.primary.withValues(alpha: 0.3),
                  GymGoColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => GymGoColors.surfaceElevated,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= data.length) {
                  return null;
                }
                final point = data[index];
                return LineTooltipItem(
                  '${_formatValue(point.value)} ${unit.displayLabel}\n',
                  GymGoTypography.labelMedium.copyWith(
                    color: point.isPr ? GymGoColors.warning : GymGoColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: _formatDateShort(point.date),
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                    if (point.isPr)
                      TextSpan(
                        text: ' (PR)',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateBottomInterval() {
    if (data.length <= 5) return 1;
    if (data.length <= 10) return 2;
    if (data.length <= 20) return 4;
    return (data.length / 5).ceil().toDouble();
  }
}
