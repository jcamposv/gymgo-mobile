import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/routine.dart';

/// Card widget displaying a routine summary
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.routine,
    this.onTap,
  });

  final Routine routine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GymGoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              _buildTypeIcon(),
              const SizedBox(width: GymGoSpacing.md),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: GymGoTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (routine.description != null &&
                        routine.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        routine.description!,
                        style: GymGoTypography.bodySmall.copyWith(
                          color: GymGoColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                LucideIcons.chevronRight,
                color: GymGoColors.textTertiary,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Info chips
          Wrap(
            spacing: GymGoSpacing.sm,
            runSpacing: GymGoSpacing.sm,
            children: [
              // Workout type chip
              _buildChip(
                icon: _getTypeIcon(routine.workoutType),
                label: routine.typeDisplay,
                color: _getTypeColor(routine.workoutType),
              ),

              // Exercise count
              _buildChip(
                icon: LucideIcons.listChecks,
                label: '${routine.exerciseCount} ejercicios',
                color: GymGoColors.info,
              ),

              // Duration estimate
              if (routine.estimatedDuration > 0)
                _buildChip(
                  icon: LucideIcons.clock,
                  label: '~${routine.estimatedDuration} min',
                  color: GymGoColors.textTertiary,
                ),

              // Scheduled date
              if (routine.scheduledDate != null)
                _buildChip(
                  icon: LucideIcons.calendar,
                  label: _formatDate(routine.scheduledDate!),
                  color: GymGoColors.warning,
                ),
            ],
          ),

          // Exercise preview (first 3 exercises)
          if (routine.exercises.isNotEmpty) ...[
            const SizedBox(height: GymGoSpacing.md),
            const Divider(color: GymGoColors.cardBorder, height: 1),
            const SizedBox(height: GymGoSpacing.md),
            _buildExercisePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    final color = _getTypeColor(routine.workoutType);
    final icon = _getTypeIcon(routine.workoutType);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GymGoTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePreview() {
    final previewExercises = routine.exercises.take(3).toList();
    final remaining = routine.exercises.length - 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...previewExercises.map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: GymGoColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Expanded(
                    child: Text(
                      ex.exerciseName,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ex.setsRepsDisplay.isNotEmpty)
                    Text(
                      ex.setsRepsDisplay,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    ),
                ],
              ),
            )),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '+ $remaining más',
              style: GymGoTypography.labelSmall.copyWith(
                color: GymGoColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getTypeIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.routine:
        return LucideIcons.dumbbell;
      case WorkoutType.wod:
        return LucideIcons.timer;
      case WorkoutType.program:
        return LucideIcons.calendarDays;
    }
  }

  Color _getTypeColor(WorkoutType type) {
    switch (type) {
      case WorkoutType.routine:
        return GymGoColors.primary;
      case WorkoutType.wod:
        return const Color(0xFFf97316); // Orange
      case WorkoutType.program:
        return const Color(0xFF8b5cf6); // Violet
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoy';
    if (dateOnly == tomorrow) return 'Mañana';

    return '${date.day}/${date.month}';
  }
}
