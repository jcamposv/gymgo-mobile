import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/program_models.dart';
import '../providers/programs_providers.dart';

/// Card showing today's workout on the dashboard
class TodayWorkoutCard extends ConsumerWidget {
  const TodayWorkoutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaysWorkoutAsync = ref.watch(todaysWorkoutProvider);

    return todaysWorkoutAsync.when(
      data: (todaysWorkout) {
        if (!todaysWorkout.hasActiveProgram) {
          return _buildNoProgram(context);
        }

        if (todaysWorkout.isProgramComplete) {
          return _buildProgramComplete(context, todaysWorkout);
        }

        return _buildTodayCard(context, ref, todaysWorkout);
      },
      loading: () => _buildLoading(),
      error: (error, _) => _buildError(context, ref, error),
    );
  }

  Widget _buildTodayCard(
    BuildContext context,
    WidgetRef ref,
    TodaysWorkout todaysWorkout,
  ) {
    final workout = todaysWorkout.workout;
    final progress = todaysWorkout.progress;
    final program = todaysWorkout.program;

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GymGoColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                ),
                child: const Icon(
                  LucideIcons.dumbbell,
                  color: GymGoColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrenamiento de hoy',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workout?.name ?? 'Día ${todaysWorkout.nextDayNumber}',
                      style: GymGoTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (todaysWorkout.isCompletedToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.sm,
                    vertical: GymGoSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        size: 14,
                        color: GymGoColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Program name and week
          Container(
            padding: const EdgeInsets.all(GymGoSpacing.sm),
            decoration: BoxDecoration(
              color: GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: GymGoColors.textSecondary,
                ),
                const SizedBox(width: GymGoSpacing.sm),
                Expanded(
                  child: Text(
                    program.name,
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Semana ${progress.currentWeek} de ${progress.totalWeeks}',
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Weekly progress
          _buildWeeklyProgress(progress),

          const SizedBox(height: GymGoSpacing.md),

          // Exercise count
          if (workout != null)
            Row(
              children: [
                const Icon(
                  LucideIcons.list,
                  size: 16,
                  color: GymGoColors.textTertiary,
                ),
                const SizedBox(width: GymGoSpacing.xs),
                Text(
                  '${workout.exerciseCount} ejercicios',
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (workout.estimatedDuration > 0) ...[
                  const Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: GymGoColors.textTertiary,
                  ),
                  const SizedBox(width: GymGoSpacing.xs),
                  Text(
                    '~${workout.estimatedDuration} min',
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),

          const SizedBox(height: GymGoSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/member/program/${program.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GymGoColors.textPrimary,
                    side: const BorderSide(color: GymGoColors.cardBorder),
                  ),
                  child: const Text('Ver programa'),
                ),
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: workout != null
                      ? () {
                          context.push('/member/workout/${workout.id}');
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GymGoColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    todaysWorkout.isCompletedToday ? 'Ver detalles' : 'Empezar',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(WeeklyProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso esta semana',
              style: GymGoTypography.labelSmall.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            Text(
              '${progress.daysCompletedThisWeek}/${progress.daysPerWeek} días',
              style: GymGoTypography.labelSmall.copyWith(
                color: GymGoColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: GymGoSpacing.xs),
        LinearProgressIndicator(
          value: progress.weekPercentage / 100,
          backgroundColor: GymGoColors.surface,
          valueColor: const AlwaysStoppedAnimation<Color>(GymGoColors.primary),
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildNoProgram(BuildContext context) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
            ),
            child: const Icon(
              LucideIcons.dumbbell,
              size: 32,
              color: GymGoColors.textTertiary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Sin programa activo',
            style: GymGoTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            'Solicita a tu entrenador que te asigne un programa de entrenamiento.',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramComplete(BuildContext context, TodaysWorkout todaysWorkout) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GymGoColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
            ),
            child: const Icon(
              LucideIcons.trophy,
              size: 32,
              color: GymGoColors.success,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            '¡Programa completado!',
            style: GymGoTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: GymGoColors.success,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            'Felicidades, has completado "${todaysWorkout.program.name}"',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GymGoSpacing.md),
          OutlinedButton(
            onPressed: () {
              context.push('/member/program/${todaysWorkout.program.id}');
            },
            child: const Text('Ver resumen'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GymGoShimmerBox(width: 48, height: 48, borderRadius: GymGoSpacing.radiusMd),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GymGoShimmerBox(width: 100, height: 14),
                    const SizedBox(height: 4),
                    GymGoShimmerBox(width: 150, height: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.md),
          GymGoShimmerBox(width: double.infinity, height: 40),
          const SizedBox(height: GymGoSpacing.md),
          GymGoShimmerBox(width: double.infinity, height: 32),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 32,
            color: GymGoColors.error,
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            'Error al cargar programa',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.sm),
          TextButton(
            onPressed: () => ref.invalidate(todaysWorkoutProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
