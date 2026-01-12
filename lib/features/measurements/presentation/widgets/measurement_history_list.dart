import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/measurement.dart';
import '../providers/measurements_providers.dart';

/// List displaying measurement history
/// Sorted by date descending (newest first)
class MeasurementHistoryList extends ConsumerWidget {
  const MeasurementHistoryList({
    super.key,
    required this.measurements,
    required this.memberId,
    required this.organizationId,
  });

  final List<Measurement> measurements;
  final String memberId;
  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: measurements.length,
      separatorBuilder: (_, __) => const SizedBox(height: GymGoSpacing.sm),
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        final isLatest = index == 0;

        return _MeasurementCard(
          measurement: measurement,
          isLatest: isLatest,
          onDelete: () => _confirmDelete(context, ref, measurement),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Measurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.cardBackground,
        title: Text(
          'Eliminar medición',
          style: GymGoTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar esta medición del ${_formatDate(measurement.measuredAt)}?',
          style: GymGoTypography.bodyMedium.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(measurementsNotifierProvider.notifier).deleteMeasurement(
                    measurementId: measurement.id,
                    memberId: memberId,
                    organizationId: organizationId,
                  );
            },
            style: TextButton.styleFrom(foregroundColor: GymGoColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _MeasurementCard extends StatefulWidget {
  const _MeasurementCard({
    required this.measurement,
    required this.isLatest,
    required this.onDelete,
  });

  final Measurement measurement;
  final bool isLatest;
  final VoidCallback onDelete;

  @override
  State<_MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<_MeasurementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.measurement;

    return GymGoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              child: Row(
                children: [
                  // Date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GymGoSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isLatest
                          ? GymGoColors.primary.withValues(alpha: 0.15)
                          : GymGoColors.surfaceLight,
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                    ),
                    child: Text(
                      _formatDate(m.measuredAt),
                      style: GymGoTypography.labelSmall.copyWith(
                        color: widget.isLatest
                            ? GymGoColors.primary
                            : GymGoColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (widget.isLatest) ...[
                    const SizedBox(width: GymGoSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: GymGoColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Última',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Quick summary
                  if (m.bodyWeightKg != null)
                    _QuickMetric(
                      value: '${m.bodyWeightKg!.toStringAsFixed(1)} kg',
                      icon: LucideIcons.scale,
                    ),

                  const SizedBox(width: GymGoSpacing.md),

                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: GymGoColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded) ...[
            const Divider(color: GymGoColors.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              child: Column(
                children: [
                  // Metrics grid
                  _MetricsGrid(measurement: m),

                  // Notes
                  if (m.notes != null && m.notes!.isNotEmpty) ...[
                    const SizedBox(height: GymGoSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(GymGoSpacing.md),
                      decoration: BoxDecoration(
                        color: GymGoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notas',
                            style: GymGoTypography.labelSmall.copyWith(
                              color: GymGoColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.notes!,
                            style: GymGoTypography.bodySmall.copyWith(
                              color: GymGoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Actions
                  const SizedBox(height: GymGoSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: GymGoColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _QuickMetric extends StatelessWidget {
  const _QuickMetric({
    required this.value,
    required this.icon,
  });

  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: GymGoColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          value,
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.measurement});

  final Measurement measurement;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricData>[];

    if (measurement.bodyHeightCm != null) {
      metrics.add(_MetricData(
        label: 'Altura',
        value: '${measurement.bodyHeightCm!.toStringAsFixed(1)} cm',
        icon: LucideIcons.moveVertical,
      ));
    }

    if (measurement.bodyWeightKg != null) {
      metrics.add(_MetricData(
        label: 'Peso',
        value: '${measurement.bodyWeightKg!.toStringAsFixed(1)} kg',
        icon: LucideIcons.scale,
      ));
    }

    if (measurement.calculatedBmi != null) {
      metrics.add(_MetricData(
        label: 'IMC',
        value: measurement.calculatedBmi!.toStringAsFixed(1),
        icon: LucideIcons.activity,
        subtitle: measurement.bmiCategory,
      ));
    }

    if (measurement.bodyFatPercentage != null) {
      metrics.add(_MetricData(
        label: '% Grasa',
        value: '${measurement.bodyFatPercentage!.toStringAsFixed(1)}%',
        icon: LucideIcons.percent,
      ));
    }

    if (measurement.muscleMassKg != null) {
      metrics.add(_MetricData(
        label: 'Masa muscular',
        value: '${measurement.muscleMassKg!.toStringAsFixed(1)} kg',
        icon: LucideIcons.dumbbell,
      ));
    }

    if (measurement.waistCm != null) {
      metrics.add(_MetricData(
        label: 'Cintura',
        value: '${measurement.waistCm!.toStringAsFixed(1)} cm',
        icon: LucideIcons.circle,
      ));
    }

    if (measurement.hipCm != null) {
      metrics.add(_MetricData(
        label: 'Cadera',
        value: '${measurement.hipCm!.toStringAsFixed(1)} cm',
        icon: LucideIcons.circle,
      ));
    }

    if (metrics.isEmpty) {
      return Text(
        'Sin datos registrados',
        style: GymGoTypography.bodySmall.copyWith(
          color: GymGoColors.textTertiary,
        ),
      );
    }

    return Wrap(
      spacing: GymGoSpacing.sm,
      runSpacing: GymGoSpacing.sm,
      children: metrics.map((m) => _MetricChip(data: m)).toList(),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.md,
        vertical: GymGoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: GymGoColors.textTertiary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.label,
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              Text(
                data.value,
                style: GymGoTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (data.subtitle != null)
                Text(
                  data.subtitle!,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.info,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
