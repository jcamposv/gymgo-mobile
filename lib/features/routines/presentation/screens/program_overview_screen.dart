import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/program_models.dart';
import '../../domain/routine.dart';
import '../providers/programs_providers.dart';

/// Screen showing program overview with all days
class ProgramOverviewScreen extends ConsumerWidget {
  const ProgramOverviewScreen({
    super.key,
    required this.programId,
  });

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(workoutByIdProvider(programId));
    final daysAsync = ref.watch(programDaysWithStatusProvider(programId));
    final progressAsync = ref.watch(programProgressProvider(programId));

    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: programAsync.when(
        data: (program) {
          if (program == null) {
            return _buildNotFound(context);
          }
          return CustomScrollView(
            slivers: [
              // App bar with program name
              _buildAppBar(context, program),

              // Progress header
              SliverToBoxAdapter(
                child: progressAsync.when(
                  data: (progress) => _buildProgressHeader(progress),
                  loading: () => _buildProgressLoading(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // Program description
              if (program.description != null &&
                  program.description!.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildDescription(program.description!),
                ),

              // Days list header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GymGoSpacing.screenHorizontal,
                    GymGoSpacing.md,
                    GymGoSpacing.screenHorizontal,
                    GymGoSpacing.sm,
                  ),
                  child: Text(
                    'Días de entrenamiento',
                    style: GymGoTypography.headlineSmall,
                  ),
                ),
              ),

              // Days list
              daysAsync.when(
                data: (days) => _buildDaysList(context, days),
                loading: () => _buildDaysLoading(),
                error: (error, _) => SliverToBoxAdapter(
                  child: _buildError(error.toString()),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.xl),
              ),
            ],
          );
        },
        loading: () => _buildFullLoading(),
        error: (error, _) => _buildFullError(context, error.toString()),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Routine program) {
    return SliverAppBar(
      backgroundColor: GymGoColors.background,
      expandedHeight: 120,
      pinned: true,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: GymGoSpacing.screenHorizontal,
          bottom: GymGoSpacing.md,
          right: GymGoSpacing.screenHorizontal,
        ),
        title: Text(
          program.name,
          style: GymGoTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: GymGoColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GymGoColors.primary.withValues(alpha: 0.1),
                GymGoColors.background,
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Program info chips
        Padding(
          padding: const EdgeInsets.only(right: GymGoSpacing.sm),
          child: Row(
            children: [
              _buildInfoChip(
                icon: LucideIcons.calendar,
                label: '${program.durationWeeks ?? 12} semanas',
              ),
              const SizedBox(width: GymGoSpacing.xs),
              _buildInfoChip(
                icon: LucideIcons.repeat,
                label: '${program.daysPerWeek ?? 3}/sem',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.sm,
        vertical: GymGoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
        border: Border.all(color: GymGoColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GymGoColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(ProgramProgress progress) {
    return Padding(
      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      child: GymGoCard(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso del programa',
                  style: GymGoTypography.labelMedium.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.sm,
                    vertical: GymGoSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: progress.isCompleted
                        ? GymGoColors.success.withValues(alpha: 0.15)
                        : GymGoColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                  ),
                  child: Text(
                    progress.isCompleted
                        ? '¡Completado!'
                        : '${progress.percentageComplete}%',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: progress.isCompleted
                          ? GymGoColors.success
                          : GymGoColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GymGoSpacing.md),
            LinearProgressIndicator(
              value: progress.percentageComplete / 100,
              backgroundColor: GymGoColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.isCompleted ? GymGoColors.success : GymGoColors.primary,
              ),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
              minHeight: 10,
            ),
            const SizedBox(height: GymGoSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Días completados',
                  value: '${progress.totalDaysCompleted}',
                  total: '/${progress.totalDaysInProgram}',
                ),
                _buildStatItem(
                  label: 'Semana actual',
                  value: '${progress.currentWeek}',
                  total: '/${progress.totalWeeks}',
                ),
                _buildStatItem(
                  label: 'Días restantes',
                  value: '${progress.daysRemaining}',
                  total: '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String total,
  }) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GymGoTypography.headlineMedium.copyWith(
                  color: GymGoColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: total,
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      child: GymGoCard(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.info,
              size: 18,
              color: GymGoColors.textSecondary,
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                description,
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysList(BuildContext context, List<ProgramDay> days) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildDayCard(context, days[index]),
          childCount: days.length,
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, ProgramDay day) {
    final workout = day.workout;

    return GymGoCard(
      margin: const EdgeInsets.only(bottom: GymGoSpacing.sm),
      padding: const EdgeInsets.all(GymGoSpacing.md),
      onTap: () {
        context.push('/member/workout/${workout.id}');
      },
      child: Row(
        children: [
          // Day number badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: day.isCompleted
                  ? GymGoColors.success.withValues(alpha: 0.15)
                  : day.isNext
                      ? GymGoColors.primary.withValues(alpha: 0.15)
                      : GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: day.isCompleted
                ? const Icon(
                    LucideIcons.checkCircle,
                    color: GymGoColors.success,
                    size: 24,
                  )
                : Center(
                    child: Text(
                      '${day.dayNumber}',
                      style: GymGoTypography.headlineSmall.copyWith(
                        color: day.isNext
                            ? GymGoColors.primary
                            : GymGoColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Day info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        day.displayName,
                        style: GymGoTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (day.isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GymGoSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GymGoColors.primary,
                          borderRadius:
                              BorderRadius.circular(GymGoSpacing.radiusFull),
                        ),
                        child: Text(
                          'Siguiente',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.list,
                      size: 14,
                      color: GymGoColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workout.exerciseCount} ejercicios',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                    if (workout.estimatedDuration > 0) ...[
                      const SizedBox(width: GymGoSpacing.md),
                      const Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: GymGoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~${workout.estimatedDuration} min',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Chevron
          const Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: GymGoColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLoading() {
    return Padding(
      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      child: GymGoCard(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Column(
          children: [
            GymGoShimmerBox(width: double.infinity, height: 20),
            const SizedBox(height: GymGoSpacing.md),
            GymGoShimmerBox(width: double.infinity, height: 10),
            const SizedBox(height: GymGoSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GymGoShimmerBox(width: 60, height: 40),
                GymGoShimmerBox(width: 60, height: 40),
                GymGoShimmerBox(width: 60, height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => GymGoCard(
            margin: const EdgeInsets.only(bottom: GymGoSpacing.sm),
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Row(
              children: [
                GymGoShimmerBox(
                  width: 48,
                  height: 48,
                  borderRadius: GymGoSpacing.radiusMd,
                ),
                const SizedBox(width: GymGoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GymGoShimmerBox(width: 120, height: 18),
                      const SizedBox(height: 4),
                      GymGoShimmerBox(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildFullLoading() {
    return const Center(
      child: CircularProgressIndicator(color: GymGoColors.primary),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Text(
          'Error: $error',
          style: GymGoTypography.bodyMedium.copyWith(
            color: GymGoColors.error,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFullError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: GymGoColors.error,
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Error al cargar programa',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error,
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.arrowLeft),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 48,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Programa no encontrado',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.arrowLeft),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
