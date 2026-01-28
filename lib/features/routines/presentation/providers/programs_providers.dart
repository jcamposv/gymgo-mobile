import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/programs_repository.dart';
import '../../domain/program_models.dart';
import '../../domain/routine.dart';

/// Repository provider
final programsRepositoryProvider = Provider<ProgramsRepository>((ref) {
  return ProgramsRepository(Supabase.instance.client);
});

/// Active program provider
final activeProgramProvider = FutureProvider<Routine?>((ref) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getActiveProgram();
});

/// Today's workout provider - main entry point for "today" experience
final todaysWorkoutProvider = FutureProvider<TodaysWorkout>((ref) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getTodaysWorkout();
});

/// Program days provider - gets all days for a program
final programDaysProvider =
    FutureProvider.family<List<Routine>, String>((ref, programId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getProgramDays(programId);
});

/// Program days with completion status provider
final programDaysWithStatusProvider =
    FutureProvider.family<List<ProgramDay>, String>((ref, programId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getProgramDaysWithStatus(programId);
});

/// Weekly progress provider
final weeklyProgressProvider =
    FutureProvider.family<WeeklyProgress, String>((ref, programId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getWeeklyProgress(programId);
});

/// Program progress provider
final programProgressProvider =
    FutureProvider.family<ProgramProgress, String>((ref, programId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getProgramProgress(programId);
});

/// Single workout provider
final workoutByIdProvider =
    FutureProvider.family<Routine?, String>((ref, workoutId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getWorkoutById(workoutId);
});

/// Completion history provider
final completionHistoryProvider =
    FutureProvider.family<List<WorkoutCompletion>, String>((ref, programId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.getCompletionHistory(programId);
});

/// Complete workout notifier
class CompleteWorkoutNotifier extends StateNotifier<AsyncValue<WorkoutCompletion?>> {
  CompleteWorkoutNotifier(this._repository) : super(const AsyncValue.data(null));

  final ProgramsRepository _repository;

  Future<bool> completeWorkout(
    String workoutId, {
    int? durationMinutes,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final completion = await _repository.completeWorkout(
        workoutId,
        durationMinutes: durationMinutes,
        notes: notes,
      );
      state = AsyncValue.data(completion);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final completeWorkoutProvider =
    StateNotifierProvider<CompleteWorkoutNotifier, AsyncValue<WorkoutCompletion?>>((ref) {
  final repository = ref.watch(programsRepositoryProvider);
  return CompleteWorkoutNotifier(repository);
});

/// Check if a workout is completed today
final workoutCompletedTodayProvider =
    FutureProvider.family<bool, String>((ref, workoutId) async {
  final repository = ref.watch(programsRepositoryProvider);
  return repository.isWorkoutCompletedToday(workoutId);
});

/// Helper to refresh all program-related providers after completion
void refreshProgramProviders(WidgetRef ref, String? programId) {
  ref.invalidate(todaysWorkoutProvider);
  ref.invalidate(activeProgramProvider);
  if (programId != null) {
    ref.invalidate(programDaysWithStatusProvider(programId));
    ref.invalidate(weeklyProgressProvider(programId));
    ref.invalidate(programProgressProvider(programId));
    ref.invalidate(completionHistoryProvider(programId));
  }
}

/// Helper to refresh workout completion status
void refreshWorkoutCompletionStatus(WidgetRef ref, String workoutId, String? programId) {
  ref.invalidate(workoutCompletedTodayProvider(workoutId));
  refreshProgramProviders(ref, programId);
}
