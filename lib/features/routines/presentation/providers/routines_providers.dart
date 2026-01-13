import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/routines_repository.dart';
import '../../domain/routine.dart';

/// Repository provider
final routinesRepositoryProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository(Supabase.instance.client);
});

/// Provider for current member's assigned routines
final myRoutinesProvider = FutureProvider<List<Routine>>((ref) async {
  final repository = ref.watch(routinesRepositoryProvider);
  return repository.getMyRoutines();
});

/// Provider for a single routine by ID
final routineByIdProvider = FutureProvider.family<Routine?, String>(
  (ref, routineId) async {
    final repository = ref.watch(routinesRepositoryProvider);
    return repository.getRoutineById(routineId);
  },
);

/// Provider for template routines (for browsing)
final templateRoutinesProvider = FutureProvider.family<List<Routine>, RoutinesFilter>(
  (ref, filter) async {
    final repository = ref.watch(routinesRepositoryProvider);
    return repository.getTemplateRoutines(
      workoutType: filter.workoutType,
      searchQuery: filter.searchQuery,
    );
  },
);

/// Filter state for routines
class RoutinesFilter {
  const RoutinesFilter({
    this.workoutType,
    this.searchQuery,
  });

  final WorkoutType? workoutType;
  final String? searchQuery;

  RoutinesFilter copyWith({
    WorkoutType? workoutType,
    String? searchQuery,
    bool clearWorkoutType = false,
    bool clearSearchQuery = false,
  }) {
    return RoutinesFilter(
      workoutType: clearWorkoutType ? null : (workoutType ?? this.workoutType),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutinesFilter &&
          runtimeType == other.runtimeType &&
          workoutType == other.workoutType &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => workoutType.hashCode ^ searchQuery.hashCode;
}

/// State provider for current filter
final routinesFilterProvider = StateProvider<RoutinesFilter>((ref) {
  return const RoutinesFilter();
});

/// Provider for selected routine (used in detail view)
final selectedRoutineIdProvider = StateProvider<String?>((ref) => null);

/// Combined provider that returns filtered routines
final filteredRoutinesProvider = FutureProvider<List<Routine>>((ref) async {
  final repository = ref.watch(routinesRepositoryProvider);
  final filter = ref.watch(routinesFilterProvider);

  // For members, we show their assigned routines
  final routines = await repository.getMyRoutines();

  // Apply client-side filtering if needed
  var filtered = routines;

  if (filter.workoutType != null) {
    filtered = filtered.where((r) => r.workoutType == filter.workoutType).toList();
  }

  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    final query = filter.searchQuery!.toLowerCase();
    filtered = filtered.where((r) =>
      r.name.toLowerCase().contains(query) ||
      (r.description?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  return filtered;
});

/// Provider to group routines by scheduled date
final routinesGroupedByDateProvider = Provider<Map<String, List<Routine>>>((ref) {
  final routinesAsync = ref.watch(myRoutinesProvider);

  return routinesAsync.when(
    data: (routines) {
      final grouped = <String, List<Routine>>{};

      for (final routine in routines) {
        final key = routine.scheduledDate != null
            ? _formatDateKey(routine.scheduledDate!)
            : 'Sin fecha';

        grouped.putIfAbsent(key, () => []).add(routine);
      }

      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

String _formatDateKey(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == today) return 'Hoy';
  if (dateOnly == tomorrow) return 'Mañana';
  if (dateOnly.isBefore(today)) return 'Anteriores';

  // Format as "Lun 15 Ene"
  const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  return '${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]}';
}
