import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';
import '../providers/benchmarks_providers.dart';
import '../widgets/pr_line_chart.dart';
import '../widgets/pr_history_item.dart';
import '../widgets/add_pr_sheet.dart';
import '../widgets/empty_state.dart';

/// PR detail screen showing exercise benchmarks with progress chart
class PRDetailScreen extends ConsumerWidget {
  const PRDetailScreen({
    super.key,
    required this.exerciseId,
  });

  final String exerciseId;

  void _showAddPRSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPRSheet(
        preselectedExerciseId: exerciseId,
        onSuccess: () {
          ref.invalidate(exerciseBenchmarksProvider(exerciseId));
          ref.invalidate(benchmarkChartDataProvider(exerciseId));
          ref.invalidate(currentPRsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benchmarksAsync = ref.watch(exerciseBenchmarksProvider(exerciseId));
    final chartDataAsync = ref.watch(benchmarkChartDataProvider(exerciseId));

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: GymGoColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: GymGoColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: benchmarksAsync.when(
          data: (benchmarks) => Text(
            benchmarks.isNotEmpty
                ? benchmarks.first.exercise?.displayName ?? 'Ejercicio'
                : 'Ejercicio',
            style: GymGoTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text('Error'),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: GymGoColors.primary),
            onPressed: () => _showAddPRSheet(context, ref),
            tooltip: 'Agregar PR',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exerciseBenchmarksProvider(exerciseId));
            ref.invalidate(benchmarkChartDataProvider(exerciseId));
          },
          color: GymGoColors.primary,
          backgroundColor: GymGoColors.surface,
          child: benchmarksAsync.when(
            data: (benchmarks) {
              if (benchmarks.isEmpty) {
                return BenchmarkEmptyState(
                  icon: LucideIcons.trophy,
                  title: 'Sin registros',
                  subtitle: 'Agrega tu primer PR para este ejercicio',
                  actionLabel: 'Agregar PR',
                  onAction: () => _showAddPRSheet(context, ref),
                );
              }

              // Find the current PR (most recent is_pr=true entry)
              final currentPR = benchmarks.firstWhere(
                (b) => b.isPr,
                orElse: () => benchmarks.first,
              );

              return CustomScrollView(
                slivers: [
                  // Current PR Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                      child: _CurrentPRCard(benchmark: currentPR),
                    ),
                  ),

                  // Progress Chart
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GymGoSpacing.screenHorizontal,
                      ),
                      child: chartDataAsync.when(
                        data: (chartData) {
                          if (chartData.length < 2) {
                            return _NoChartPlaceholder();
                          }
                          return _ChartSection(
                            chartData: chartData,
                            unit: currentPR.unit,
                          );
                        },
                        loading: () => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: GymGoColors.cardBackground,
                            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: GymGoColors.primary),
                          ),
                        ),
                        error: (_, __) => _NoChartPlaceholder(),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: GymGoSpacing.lg),
                  ),

                  // History section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GymGoSpacing.screenHorizontal,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historial',
                            style: GymGoTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${benchmarks.length} registros',
                            style: GymGoTypography.bodySmall.copyWith(
                              color: GymGoColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: GymGoSpacing.sm),
                  ),

                  // History list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GymGoSpacing.screenHorizontal,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final benchmark = benchmarks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
                            child: PRHistoryItem(
                              benchmark: benchmark,
                              onTap: () {
                                // Could show edit dialog here
                              },
                            ),
                          );
                        },
                        childCount: benchmarks.length,
                      ),
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: GymGoSpacing.xxl + 80),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: GymGoColors.primary),
            ),
            error: (error, _) => BenchmarkEmptyState(
              icon: LucideIcons.alertCircle,
              title: 'Error al cargar',
              subtitle: error.toString(),
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(exerciseBenchmarksProvider(exerciseId)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPRSheet(context, ref),
        backgroundColor: GymGoColors.primary,
        foregroundColor: GymGoColors.background,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Agregar PR'),
      ),
    );
  }
}

/// Current PR highlight card
class _CurrentPRCard extends StatelessWidget {
  const _CurrentPRCard({required this.benchmark});

  final ExerciseBenchmark benchmark;

  String _formatDate(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GymGoColors.primary.withValues(alpha: 0.2),
            GymGoColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        border: Border.all(
          color: GymGoColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              child: benchmark.exercise?.gifUrl != null
                  ? CachedNetworkImage(
                      imageUrl: benchmark.exercise!.gifUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildPlaceholderIcon(),
                      errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
                    )
                  : _buildPlaceholderIcon(),
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.trophy,
                      size: 16,
                      color: GymGoColors.primary,
                    ),
                    const SizedBox(width: GymGoSpacing.xxs),
                    Text(
                      'Record Actual',
                      style: GymGoTypography.labelMedium.copyWith(
                        color: GymGoColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GymGoSpacing.xs),
                Text(
                  benchmark.formattedValue,
                  style: GymGoTypography.displaySmall.copyWith(
                    color: GymGoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (benchmark.formattedReps != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    benchmark.formattedReps!,
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: GymGoSpacing.xxs),
                Text(
                  'Logrado el ${_formatDate(benchmark.achievedAt)}',
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        LucideIcons.dumbbell,
        size: 28,
        color: GymGoColors.textTertiary,
      ),
    );
  }
}

/// Chart section with header
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.chartData,
    required this.unit,
  });

  final List<BenchmarkChartPoint> chartData;
  final BenchmarkUnit unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(color: GymGoColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso',
            style: GymGoTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          _buildImprovementIndicator(),
          const SizedBox(height: GymGoSpacing.md),
          SizedBox(
            height: 200,
            child: PRLineChart(
              data: chartData,
              unit: unit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementIndicator() {
    if (chartData.length < 2) return const SizedBox.shrink();

    final first = chartData.first.value;
    final last = chartData.last.value;
    final isImproved = unit.isTimeBased ? last < first : last > first;
    final diff = unit.isTimeBased ? first - last : last - first;
    final percentage = ((diff / first) * 100).abs();

    return Row(
      children: [
        Icon(
          isImproved ? LucideIcons.trendingUp : LucideIcons.trendingDown,
          size: 16,
          color: isImproved ? GymGoColors.success : GymGoColors.error,
        ),
        const SizedBox(width: GymGoSpacing.xxs),
        Text(
          '${isImproved ? '+' : '-'}${percentage.toStringAsFixed(1)}%',
          style: GymGoTypography.labelMedium.copyWith(
            color: isImproved ? GymGoColors.success : GymGoColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: GymGoSpacing.xs),
        Text(
          'desde el primer registro',
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Placeholder when not enough data for chart
class _NoChartPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(color: GymGoColors.cardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.lineChart,
              size: 32,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'Necesitas al menos 2 registros para ver el gráfico',
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
