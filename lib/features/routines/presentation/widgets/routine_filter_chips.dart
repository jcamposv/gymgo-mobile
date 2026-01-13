import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/routine.dart';

/// Filter chips for routine types
class RoutineFilterChips extends StatelessWidget {
  const RoutineFilterChips({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
  });

  final WorkoutType? selectedType;
  final void Function(WorkoutType?) onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            icon: LucideIcons.layoutGrid,
            isSelected: selectedType == null,
            onTap: () => onTypeSelected(null),
          ),
          const SizedBox(width: GymGoSpacing.sm),
          _FilterChip(
            label: 'Rutinas',
            icon: LucideIcons.dumbbell,
            isSelected: selectedType == WorkoutType.routine,
            onTap: () => onTypeSelected(
              selectedType == WorkoutType.routine ? null : WorkoutType.routine,
            ),
            color: GymGoColors.primary,
          ),
          const SizedBox(width: GymGoSpacing.sm),
          _FilterChip(
            label: 'WOD',
            icon: LucideIcons.timer,
            isSelected: selectedType == WorkoutType.wod,
            onTap: () => onTypeSelected(
              selectedType == WorkoutType.wod ? null : WorkoutType.wod,
            ),
            color: const Color(0xFFf97316), // Orange
          ),
          const SizedBox(width: GymGoSpacing.sm),
          _FilterChip(
            label: 'Programas',
            icon: LucideIcons.calendarDays,
            isSelected: selectedType == WorkoutType.program,
            onTap: () => onTypeSelected(
              selectedType == WorkoutType.program ? null : WorkoutType.program,
            ),
            color: const Color(0xFF8b5cf6), // Violet
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? GymGoColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.15)
              : GymGoColors.surfaceLight,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? effectiveColor : GymGoColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? effectiveColor : GymGoColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GymGoTypography.labelMedium.copyWith(
                color: isSelected ? effectiveColor : GymGoColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
