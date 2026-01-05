import 'package:flutter/material.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Time slot chip selector for filtering classes
class TimeSlotSelector extends StatelessWidget {
  const TimeSlotSelector({
    super.key,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.availableSlots,
  });

  final String? selectedSlot;
  final ValueChanged<String?> onSlotSelected;
  final List<TimeSlot> availableSlots;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.md),
      child: Row(
        children: [
          _TimeSlotChip(
            label: 'Todas',
            isSelected: selectedSlot == null,
            onTap: () => onSlotSelected(null),
          ),
          ...availableSlots.map((slot) => _TimeSlotChip(
            label: slot.label,
            isSelected: selectedSlot == slot.id,
            onTap: () => onSlotSelected(slot.id),
            classCount: slot.classCount > 0 ? slot.classCount : null,
          )),
        ],
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.classCount,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? classCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: GymGoSpacing.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.md,
                vertical: GymGoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? GymGoColors.primary
                    : GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? GymGoColors.primary
                      : GymGoColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GymGoTypography.labelMedium.copyWith(
                      color: isSelected
                          ? GymGoColors.background
                          : GymGoColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (classCount != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GymGoColors.background.withValues(alpha: 0.2)
                            : GymGoColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        classCount.toString(),
                        style: GymGoTypography.labelSmall.copyWith(
                          color: isSelected
                              ? GymGoColors.background
                              : GymGoColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Represents a time slot for filtering
class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.label,
    required this.startHour,
    required this.endHour,
    this.classCount = 0,
  });

  final String id;
  final String label;
  final int startHour;
  final int endHour;
  final int classCount;

  /// Default time slots
  static const List<TimeSlot> defaultSlots = [
    TimeSlot(id: 'morning', label: 'Mañana', startHour: 6, endHour: 12),
    TimeSlot(id: 'afternoon', label: 'Tarde', startHour: 12, endHour: 18),
    TimeSlot(id: 'evening', label: 'Noche', startHour: 18, endHour: 23),
  ];
}
