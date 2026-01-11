import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Time slot chips in a wrap layout (matching reference design)
class TimeSlotChips extends StatelessWidget {
  const TimeSlotChips({
    super.key,
    required this.timeSlots,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  final List<String> timeSlots;
  final String? selectedTime;
  final ValueChanged<String?> onTimeSelected;

  @override
  Widget build(BuildContext context) {
    if (timeSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.screenHorizontal),
      child: Wrap(
        spacing: GymGoSpacing.xs,
        runSpacing: GymGoSpacing.xs,
        children: [
          // "Todas" chip to show all times
          _TimeChip(
            label: 'Todas',
            isSelected: selectedTime == null,
            onTap: () {
              HapticFeedback.selectionClick();
              onTimeSelected(null);
            },
          ),
          // Time slot chips
          ...timeSlots.map((time) {
            final isSelected = selectedTime == time;
            return _TimeChip(
              label: time,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                onTimeSelected(time);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? GymGoColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? GymGoColors.primary : GymGoColors.textTertiary,
            width: isSelected ? 1 : 1,
            style: isSelected ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Text(
          label,
          style: GymGoTypography.labelMedium.copyWith(
            color: isSelected ? GymGoColors.background : GymGoColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Helper to extract unique time slots from a list of classes
List<String> extractTimeSlots(List<dynamic> classes) {
  final times = <String>{};
  for (final cls in classes) {
    if (cls.startTime != null) {
      times.add(cls.startTime as String);
    }
  }
  final sortedTimes = times.toList()..sort();
  return sortedTimes;
}
