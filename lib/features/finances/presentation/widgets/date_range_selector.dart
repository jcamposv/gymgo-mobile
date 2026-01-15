import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../providers/finances_providers.dart';

/// Date range selector for finance filters
class DateRangeSelector extends ConsumerWidget {
  const DateRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(dateRangeFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.md,
        vertical: GymGoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: GymGoColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.calendar,
            size: 18,
            color: GymGoColors.primary,
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Expanded(
            child: InkWell(
              onTap: () => _showDateRangeOptions(context, ref),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDateRange(dateRange),
                      style: GymGoTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: GymGoColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateRangeFilter filter) {
    if (filter.startDate == null && filter.endDate == null) {
      return filter.label;
    }

    final dateFormat = DateFormat('dd MMM', 'es');
    final yearFormat = DateFormat('yyyy', 'es');

    if (filter.startDate != null && filter.endDate != null) {
      final startYear = yearFormat.format(filter.startDate!);
      final endYear = yearFormat.format(filter.endDate!);

      if (startYear == endYear) {
        return '${dateFormat.format(filter.startDate!)} - ${dateFormat.format(filter.endDate!)} $startYear';
      } else {
        return '${dateFormat.format(filter.startDate!)} $startYear - ${dateFormat.format(filter.endDate!)} $endYear';
      }
    }

    return filter.label;
  }

  void _showDateRangeOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GymGoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => _DateRangeBottomSheet(ref: ref),
    );
  }
}

class _DateRangeBottomSheet extends StatelessWidget {
  const _DateRangeBottomSheet({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(dateRangeFilterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seleccionar período',
                  style: GymGoTypography.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: GymGoSpacing.md),

            // Quick options
            _DateRangeOption(
              label: 'Este mes',
              isSelected: currentFilter.label == 'Este mes',
              onTap: () {
                ref.read(dateRangeFilterProvider.notifier).state =
                    DateRangeFilter.thisMonth();
                Navigator.pop(context);
              },
            ),
            _DateRangeOption(
              label: 'Mes pasado',
              isSelected: currentFilter.label == 'Mes pasado',
              onTap: () {
                ref.read(dateRangeFilterProvider.notifier).state =
                    DateRangeFilter.lastMonth();
                Navigator.pop(context);
              },
            ),
            _DateRangeOption(
              label: 'Últimos 3 meses',
              isSelected: currentFilter.label == 'Últimos 3 meses',
              onTap: () {
                final now = DateTime.now();
                ref.read(dateRangeFilterProvider.notifier).state =
                    DateRangeFilter(
                  startDate: DateTime(now.year, now.month - 2, 1),
                  endDate: DateTime(now.year, now.month + 1, 0),
                  label: 'Últimos 3 meses',
                );
                Navigator.pop(context);
              },
            ),
            _DateRangeOption(
              label: 'Este año',
              isSelected: currentFilter.label == 'Este año',
              onTap: () {
                final now = DateTime.now();
                ref.read(dateRangeFilterProvider.notifier).state =
                    DateRangeFilter(
                  startDate: DateTime(now.year, 1, 1),
                  endDate: DateTime(now.year, 12, 31),
                  label: 'Este año',
                );
                Navigator.pop(context);
              },
            ),
            _DateRangeOption(
              label: 'Todo',
              isSelected: currentFilter.label == 'Todo',
              onTap: () {
                ref.read(dateRangeFilterProvider.notifier).state =
                    DateRangeFilter.allTime();
                Navigator.pop(context);
              },
            ),

            const Divider(height: GymGoSpacing.lg),

            // Custom range option
            _DateRangeOption(
              label: 'Rango personalizado',
              icon: LucideIcons.calendarRange,
              isSelected: false,
              onTap: () async {
                Navigator.pop(context);
                await _showCustomDateRangePicker(context, ref);
              },
            ),

            const SizedBox(height: GymGoSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDateRangePicker(
      BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2, 1, 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: GymGoColors.primary,
                  onPrimary: Colors.white,
                  surface: GymGoColors.surface,
                  onSurface: GymGoColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateFormat = DateFormat('dd MMM', 'es');
      ref.read(dateRangeFilterProvider.notifier).state = DateRangeFilter(
        startDate: picked.start,
        endDate: picked.end,
        label:
            '${dateFormat.format(picked.start)} - ${dateFormat.format(picked.end)}',
      );
    }
  }
}

class _DateRangeOption extends StatelessWidget {
  const _DateRangeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? GymGoColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color:
                    isSelected ? GymGoColors.primary : GymGoColors.textSecondary,
              ),
              const SizedBox(width: GymGoSpacing.sm),
            ],
            Expanded(
              child: Text(
                label,
                style: GymGoTypography.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? GymGoColors.primary
                      : GymGoColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: GymGoColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
