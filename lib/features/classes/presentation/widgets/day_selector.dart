import 'package:flutter/material.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Day selector with week navigation for class scheduling
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.weekDates,
    this.onPreviousWeek,
    this.onNextWeek,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final List<DateTime> weekDates;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;

  static const List<String> _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GymGoColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Week navigation header
          _buildWeekHeader(),
          const SizedBox(height: GymGoSpacing.sm),
          // Day selector row
          _buildDayRow(),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final firstDay = weekDates.first;
    final lastDay = weekDates.last;
    final monthYear = _formatMonthYear(firstDay, lastDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPreviousWeek,
            icon: const Icon(
              Icons.chevron_left,
              color: GymGoColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            monthYear,
            style: GymGoTypography.labelLarge.copyWith(
              color: GymGoColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: onNextWeek,
            icon: const Icon(
              Icons.chevron_right,
              color: GymGoColors.textSecondary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = weekDates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final isPast = date.isBefore(DateTime.now()) && !isToday;

          return Expanded(
            child: GestureDetector(
              onTap: isPast ? null : () => onDateSelected(date),
              child: _DayItem(
                dayLabel: _dayLabels[index],
                dayNumber: date.day.toString(),
                isSelected: isSelected,
                isToday: isToday,
                isPast: isPast,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatMonthYear(DateTime first, DateTime last) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    if (first.month == last.month) {
      return '${months[first.month - 1]} ${first.year}';
    } else {
      return '${months[first.month - 1]} - ${months[last.month - 1]} ${last.year}';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayItem extends StatelessWidget {
  const _DayItem({
    required this.dayLabel,
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.isPast,
  });

  final String dayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? GymGoColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: isToday && !isSelected
            ? Border.all(color: GymGoColors.primary.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: GymGoTypography.labelSmall.copyWith(
              color: _getLabelColor(),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dayNumber,
            style: GymGoTypography.bodyLarge.copyWith(
              color: _getNumberColor(),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLabelColor() {
    if (isSelected) return GymGoColors.background;
    if (isPast) return GymGoColors.textTertiary;
    return GymGoColors.textSecondary;
  }

  Color _getNumberColor() {
    if (isSelected) return GymGoColors.background;
    if (isPast) return GymGoColors.textTertiary;
    if (isToday) return GymGoColors.primary;
    return GymGoColors.textPrimary;
  }
}
