import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/role_providers.dart';
import '../../data/classes_repository.dart';
import '../../domain/gym_class.dart';

/// Repository provider
final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassesRepository(Supabase.instance.client);
});

/// Selected date provider
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Selected time slot filter provider
final selectedTimeSlotProvider = StateProvider<String?>((ref) {
  return null;
});

/// Week dates provider - generates dates for the current week view
final weekDatesProvider = Provider<List<DateTime>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);

  // Get Monday of the selected week
  final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  return List.generate(7, (index) => monday.add(Duration(days: index)));
});

/// Classes for selected date provider
final classesProvider = FutureProvider<List<GymClass>>((ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  // Get organizationId from profile provider (already loaded)
  final organizationId = await ref.watch(currentOrganizationIdAsyncProvider.future);

  return repository.getClassesByDate(selectedDate, organizationId: organizationId);
});

/// Filtered classes based on time slot
final filteredClassesProvider = Provider<AsyncValue<List<GymClass>>>((ref) {
  final classesAsync = ref.watch(classesProvider);
  final timeSlot = ref.watch(selectedTimeSlotProvider);

  return classesAsync.whenData((classes) {
    if (timeSlot == null) return classes;

    return classes.where((gymClass) {
      final hour = gymClass.startHour;

      switch (timeSlot) {
        case 'morning':
          return hour >= 6 && hour < 12;
        case 'afternoon':
          return hour >= 12 && hour < 18;
        case 'evening':
          return hour >= 18 && hour < 23;
        default:
          return true;
      }
    }).toList();
  });
});

/// Loading state for reservation actions
final reservationLoadingProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// Notifier for class actions (reserve/cancel)
class ClassActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ClassActionsNotifier(this._repository, this._ref) : super(const AsyncData(null));

  final ClassesRepository _repository;
  final Ref _ref;

  Future<void> reserveClass(String classId) async {
    // Set loading for this specific class
    _ref.read(reservationLoadingProvider.notifier).update(
      (state) => {...state, classId},
    );

    try {
      await _repository.reserveClass(classId);
      // Refresh classes list
      _ref.invalidate(classesProvider);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    } finally {
      _ref.read(reservationLoadingProvider.notifier).update(
        (state) => state..remove(classId),
      );
    }
  }

  Future<void> cancelReservation(String classId) async {
    // Set loading for this specific class
    _ref.read(reservationLoadingProvider.notifier).update(
      (state) => {...state, classId},
    );

    try {
      await _repository.cancelReservation(classId);
      // Refresh classes list
      _ref.invalidate(classesProvider);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    } finally {
      _ref.read(reservationLoadingProvider.notifier).update(
        (state) => state..remove(classId),
      );
    }
  }
}

/// Class actions provider
final classActionsProvider = StateNotifierProvider<ClassActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(classesRepositoryProvider);
  return ClassActionsNotifier(repository, ref);
});

/// Next user class provider (for dashboard)
final nextUserClassProvider = FutureProvider<GymClass?>((ref) async {
  final repository = ref.watch(classesRepositoryProvider);
  try {
    final result = await repository.getNextUserClass();
    return result;
  } catch (e, stack) {
    print('nextUserClassProvider error: $e');
    print('Stack: $stack');
    rethrow;
  }
});

/// Helper to navigate weeks
void navigateWeek(WidgetRef ref, {required bool forward}) {
  final currentDate = ref.read(selectedDateProvider);
  final days = forward ? 7 : -7;
  ref.read(selectedDateProvider.notifier).state = currentDate.add(Duration(days: days));
}

/// Helper to select a specific date
void selectDate(WidgetRef ref, DateTime date) {
  ref.read(selectedDateProvider.notifier).state = date;
}
