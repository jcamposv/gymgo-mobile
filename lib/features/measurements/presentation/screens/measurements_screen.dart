import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../profile/presentation/providers/member_providers.dart';
import '../../domain/measurement.dart';
import '../providers/measurements_providers.dart';
import '../widgets/add_measurement_sheet.dart';
import '../widgets/measurement_summary_cards.dart';
import '../widgets/measurement_history_list.dart';
import '../widgets/metric_line_chart.dart';
import '../widgets/metric_selector.dart';

/// Main screen for viewing and managing measurements
class MeasurementsScreen extends ConsumerWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: GymGoColors.background,
        title: Text(
          'Mediciones',
          style: GymGoTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _showAddMeasurementSheet(context, ref),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GymGoColors.primary,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: const Icon(
                LucideIcons.plus,
                color: GymGoColors.background,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: GymGoSpacing.sm),
        ],
      ),
      body: memberAsync.when(
        data: (member) {
          if (member == null || member.organizationId == null) {
            return const Center(
              child: Text(
                'No se encontró información del miembro',
                style: TextStyle(color: GymGoColors.textSecondary),
              ),
            );
          }

          return _MeasurementsContent(
            memberId: member.id,
            organizationId: member.organizationId!,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                color: GymGoColors.error,
                size: 48,
              ),
              const SizedBox(height: GymGoSpacing.md),
              Text(
                'Error al cargar datos',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMeasurementSheet(BuildContext context, WidgetRef ref) {
    final member = ref.read(currentMemberProvider).valueOrNull;
    if (member == null || member.organizationId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMeasurementSheet(
        memberId: member.id,
        organizationId: member.organizationId!,
      ),
    );
  }
}

class _MeasurementsContent extends ConsumerWidget {
  const _MeasurementsContent({
    required this.memberId,
    required this.organizationId,
  });

  final String memberId;
  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (memberId: memberId, organizationId: organizationId);
    final measurementsAsync = ref.watch(memberMeasurementsProvider(params));
    final chartDataAsync = ref.watch(measurementsChartDataProvider(memberId));
    final selectedMetric = ref.watch(selectedMetricProvider);

    return RefreshIndicator(
      color: GymGoColors.primary,
      backgroundColor: GymGoColors.cardBackground,
      onRefresh: () async {
        ref.invalidate(memberMeasurementsProvider(params));
        ref.invalidate(measurementsChartDataProvider(memberId));
      },
      child: measurementsAsync.when(
        data: (measurements) {
          if (measurements.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                MeasurementSummaryCards(
                  latestMeasurement: measurements.first,
                  previousMeasurement: measurements.length > 1 ? measurements[1] : null,
                ),

                const SizedBox(height: GymGoSpacing.xl),

                // Progress Chart Section
                _buildSectionHeader('Progreso'),
                const SizedBox(height: GymGoSpacing.md),

                // Metric Selector
                MetricSelector(
                  selectedMetric: selectedMetric,
                  onMetricSelected: (metric) {
                    ref.read(selectedMetricProvider.notifier).state = metric;
                  },
                ),

                const SizedBox(height: GymGoSpacing.md),

                // Chart
                chartDataAsync.when(
                  data: (chartData) => MetricLineChart(
                    measurements: chartData,
                    metricType: selectedMetric,
                  ),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: GymGoColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Error al cargar gráfico',
                        style: TextStyle(color: GymGoColors.textSecondary),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: GymGoSpacing.xl),

                // History Section
                _buildSectionHeader('Historial'),
                const SizedBox(height: GymGoSpacing.md),

                MeasurementHistoryList(
                  measurements: measurements,
                  memberId: memberId,
                  organizationId: organizationId,
                ),

                const SizedBox(height: GymGoSpacing.xl),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                color: GymGoColors.error,
                size: 48,
              ),
              const SizedBox(height: GymGoSpacing.md),
              Text(
                'Error al cargar mediciones',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
              const SizedBox(height: GymGoSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(memberMeasurementsProvider(params)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: GymGoColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                LucideIcons.ruler,
                color: GymGoColors.info,
                size: 48,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Sin mediciones',
              style: GymGoTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'Registra tu primera medición para\ncomenzar a ver tu progreso',
              textAlign: TextAlign.center,
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _showAddMeasurementSheet(context, ref),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Agregar medición'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.primary,
                foregroundColor: GymGoColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.xl,
                  vertical: GymGoSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMeasurementSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMeasurementSheet(
        memberId: memberId,
        organizationId: organizationId,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GymGoTypography.labelSmall.copyWith(
        color: GymGoColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}
