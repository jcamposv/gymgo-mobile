import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';

/// Card showing today's assigned workout
class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({
    super.key,
    this.workoutName,
    this.exerciseCount,
    this.estimatedDuration,
    this.muscleGroups,
    this.isCompleted = false,
    this.isLoading = false,
    this.onTap,
    this.onStart,
    this.onViewAll,
  });

  final String? workoutName;
  final int? exerciseCount;
  final int? estimatedDuration; // in minutes
  final List<String>? muscleGroups;
  final bool isCompleted;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onViewAll;

  bool get hasWorkout => workoutName != null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (!hasWorkout) {
      return _buildEmptyState();
    }

    return _buildWorkoutCard();
  }

  Widget _buildLoadingState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GymGoShimmerBox(width: 48, height: 48),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    GymGoShimmerBox(width: 100, height: 12),
                    SizedBox(height: 8),
                    GymGoShimmerBox(width: 140, height: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.md),
          const GymGoShimmerBox(height: 44),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      onTap: onViewAll,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: GymGoColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: const Icon(
              LucideIcons.dumbbell,
              color: GymGoColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Sin rutina para hoy',
            style: GymGoTypography.titleMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xxs),
          Text(
            'Tu entrenador aún no ha asignado rutina',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GymGoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewAll,
              icon: const Icon(LucideIcons.list, size: 18),
              label: const Text('Ver mis rutinas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GymGoColors.warning,
                side: BorderSide(
                  color: GymGoColors.warning.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? GymGoColors.success.withValues(alpha: 0.15)
                      : GymGoColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                ),
                child: Icon(
                  isCompleted ? LucideIcons.checkCircle : LucideIcons.dumbbell,
                  color: isCompleted ? GymGoColors.success : GymGoColors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'RUTINA DE HOY',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: isCompleted
                                ? GymGoColors.success
                                : GymGoColors.warning,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GymGoSpacing.xs,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: GymGoColors.success.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(GymGoSpacing.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.check,
                                  size: 12,
                                  color: GymGoColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completada',
                                  style: GymGoTypography.labelSmall.copyWith(
                                    color: GymGoColors.success,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workoutName!,
                      style: GymGoTypography.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Workout details
          Container(
            padding: const EdgeInsets.all(GymGoSpacing.sm),
            decoration: BoxDecoration(
              color: GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Row(
              children: [
                if (exerciseCount != null)
                  _buildDetailItem(
                    icon: LucideIcons.listChecks,
                    text: '$exerciseCount ejercicios',
                  ),
                if (exerciseCount != null && estimatedDuration != null)
                  const SizedBox(width: GymGoSpacing.lg),
                if (estimatedDuration != null)
                  _buildDetailItem(
                    icon: LucideIcons.timer,
                    text: '~$estimatedDuration min',
                  ),
              ],
            ),
          ),

          // Muscle groups
          if (muscleGroups != null && muscleGroups!.isNotEmpty) ...[
            const SizedBox(height: GymGoSpacing.sm),
            Wrap(
              spacing: GymGoSpacing.xs,
              runSpacing: GymGoSpacing.xs,
              children: muscleGroups!.take(4).map((group) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.cardBorder,
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                  child: Text(
                    group,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: GymGoSpacing.md),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCompleted ? onTap : onStart,
              icon: Icon(
                isCompleted ? LucideIcons.eye : LucideIcons.play,
                size: 18,
              ),
              label: Text(isCompleted ? 'Ver resumen' : 'Comenzar rutina'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted
                    ? GymGoColors.cardBackground
                    : GymGoColors.primary,
                foregroundColor: isCompleted
                    ? GymGoColors.textPrimary
                    : GymGoColors.background,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: GymGoColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
