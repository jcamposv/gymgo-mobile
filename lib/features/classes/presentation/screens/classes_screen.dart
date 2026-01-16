import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/booking_limit.dart';
import '../providers/classes_providers.dart';
import '../widgets/class_card.dart';
import '../widgets/day_selector.dart';
import '../widgets/time_slot_selector.dart';

/// Classes/Reservations screen with day selector and class list
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekDates = ref.watch(weekDatesProvider);
    final filteredClasses = ref.watch(filteredClassesProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final loadingClasses = ref.watch(reservationLoadingProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: GymGoColors.background,
        title: const Text('Clases'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(LucideIcons.filter, size: 20),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day Selector - Fixed at top
          DaySelector(
            selectedDate: selectedDate,
            onDateSelected: (date) => selectDate(ref, date),
            weekDates: weekDates,
            onPreviousWeek: () => navigateWeek(ref, forward: false),
            onNextWeek: () => navigateWeek(ref, forward: true),
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Time Slot Selector
          TimeSlotSelector(
            selectedSlot: selectedTimeSlot,
            onSlotSelected: (slot) {
              ref.read(selectedTimeSlotProvider.notifier).state = slot;
            },
            availableSlots: TimeSlot.defaultSlots,
          ),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GymGoSpacing.screenHorizontal,
              GymGoSpacing.lg,
              GymGoSpacing.screenHorizontal,
              GymGoSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateHeader(selectedDate),
                  style: GymGoTypography.labelLarge.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
                filteredClasses.whenOrNull(
                  data: (classes) => Text(
                    '${classes.length} ${classes.length == 1 ? 'clase' : 'clases'}',
                    style: GymGoTypography.labelMedium.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ) ?? const SizedBox.shrink(),
              ],
            ),
          ),

          // Class list
          Expanded(
            child: filteredClasses.when(
              data: (classes) {
                if (classes.isEmpty) {
                  return _buildEmptyState(selectedDate);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                    vertical: GymGoSpacing.sm,
                  ),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final gymClass = classes[index];
                    final isLoading = loadingClasses.contains(gymClass.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: GymGoSpacing.md),
                      child: ClassCard(
                        gymClass: gymClass,
                        isLoading: isLoading,
                        onReserve: () => _handleReserve(context, ref, gymClass.id),
                        onCancel: () => _handleCancel(context, ref, gymClass.id),
                      ),
                    );
                  },
                );
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString(), ref),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    if (_isSameDay(date, today)) {
      return 'Hoy, ${date.day} de ${months[date.month - 1]}';
    } else if (_isSameDay(date, tomorrow)) {
      return 'Mañana, ${date.day} de ${months[date.month - 1]}';
    }

    return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState(DateTime date) {
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
              ),
              child: Icon(
                isPast ? LucideIcons.calendarX : LucideIcons.calendar,
                size: 36,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              isPast ? 'Sin clases registradas' : 'No hay clases programadas',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              isPast
                  ? 'No hay historial de clases para esta fecha'
                  : 'Selecciona otro día o revisa más tarde',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
        vertical: GymGoSpacing.sm,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: GymGoSpacing.md),
          child: GymGoCard(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GymGoShimmerBox(width: 100, height: 16),
                    GymGoShimmerBox(width: 60, height: 20),
                  ],
                ),
                const SizedBox(height: GymGoSpacing.md),
                GymGoShimmerBox(width: 180, height: 20),
                const SizedBox(height: GymGoSpacing.sm),
                GymGoShimmerBox(width: 140, height: 14),
                const SizedBox(height: GymGoSpacing.md),
                GymGoShimmerBox(width: double.infinity, height: 44),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GymGoColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                size: 36,
                color: GymGoColors.error,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Error al cargar clases',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error,
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(classesProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.primary,
                foregroundColor: GymGoColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReserve(BuildContext context, WidgetRef ref, String classId) async {
    try {
      await ref.read(classActionsProvider.notifier).reserveClass(classId);
      if (context.mounted) {
        GymGoToast.success(context, 'Reserva confirmada');
      }
    } on DailyClassLimitException catch (e) {
      // Handle daily limit reached (WEB contract)
      if (context.mounted) {
        await DailyLimitDialog.show(
          context,
          exception: e,
          onViewReservations: () {
            // Navigate to member classes route to show today's reservations
            // This matches WEB behavior "Ver mis reservas de hoy"
            context.go(Routes.memberClasses);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        GymGoToast.error(context, e.toString());
      }
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref, String classId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.surface,
        title: const Text('Cancelar reserva'),
        content: const Text('¿Estás seguro que deseas cancelar tu reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(classActionsProvider.notifier).cancelReservation(classId);
      if (context.mounted) {
        GymGoToast.success(context, 'Reserva cancelada');
      }
    } catch (e) {
      if (context.mounted) {
        GymGoToast.error(context, e.toString());
      }
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GymGoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(GymGoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GymGoColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Filtros',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Más filtros próximamente...',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xl),
          ],
        ),
      ),
    );
  }
}
