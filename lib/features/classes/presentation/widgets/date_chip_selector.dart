import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Horizontal scrollable date chip selector
class DateChipSelector extends StatefulWidget {
  const DateChipSelector({
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

  @override
  State<DateChipSelector> createState() => _DateChipSelectorState();
}

class _DateChipSelectorState extends State<DateChipSelector> {
  late ScrollController _scrollController;

  static const List<String> _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(DateChipSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final index = widget.weekDates.indexWhere((d) => _isSameDay(d, widget.selectedDate));
    if (index >= 0 && _scrollController.hasClients) {
      const itemWidth = 56.0;
      const spacing = GymGoSpacing.sm;
      final offset = (index * (itemWidth + spacing)) - (MediaQuery.of(context).size.width / 2) + itemWidth / 2;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GymGoColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week header with navigation
          _buildWeekHeader(),
          const SizedBox(height: GymGoSpacing.md),
          // Horizontal scrollable date chips
          _buildDateChips(),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final firstDay = widget.weekDates.first;
    final lastDay = widget.weekDates.last;
    final monthYear = _formatMonthYear(firstDay, lastDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.screenHorizontal),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onPreviousWeek?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: GymGoColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          Text(
            monthYear,
            style: GymGoTypography.titleMedium.copyWith(
              color: GymGoColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onNextWeek?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: GymGoColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChips() {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.screenHorizontal),
        itemCount: widget.weekDates.length,
        itemBuilder: (context, index) {
          final date = widget.weekDates[index];
          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isSameDay(date, DateTime.now());
          final isPast = date.isBefore(DateTime.now()) && !isToday;

          return Padding(
            padding: EdgeInsets.only(
              right: index < widget.weekDates.length - 1 ? GymGoSpacing.sm : 0,
            ),
            child: _DateChip(
              dayLabel: _dayLabels[date.weekday - 1],
              dayNumber: date.day.toString(),
              isSelected: isSelected,
              isToday: isToday,
              isPast: isPast,
              onTap: isPast ? null : () {
                HapticFeedback.selectionClick();
                widget.onDateSelected(date);
              },
            ),
          );
        },
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

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.dayLabel,
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.isPast,
    this.onTap,
  });

  final String dayLabel;
  final String dayNumber;
  final bool isSelected;
  final bool isToday;
  final bool isPast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? GymGoColors.primary : GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: isToday && !isSelected
              ? Border.all(color: GymGoColors.primary.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              style: GymGoTypography.titleMedium.copyWith(
                color: _getNumberColor(),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
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
