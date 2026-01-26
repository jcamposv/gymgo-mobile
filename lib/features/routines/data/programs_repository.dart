import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/program_models.dart';
import '../domain/routine.dart';

/// Repository for managing training programs
/// Implements the same algorithm as web/src/actions/program.actions.ts
class ProgramsRepository {
  ProgramsRepository(this._client);

  final SupabaseClient _client;

  // Default values matching web
  static const int _defaultDaysPerWeek = 3;
  static const int _defaultDurationWeeks = 12;

  /// Get member context (id and organization_id)
  /// Tries to find member by user_id first, then by email if not found
  Future<({String memberId, String organizationId})?> _getMemberContext() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // First get profile for org and email
    final profileResponse = await _client
        .from('profiles')
        .select('organization_id, email')
        .eq('id', user.id)
        .maybeSingle();

    if (profileResponse == null || profileResponse['organization_id'] == null) {
      debugPrint('ProgramsRepository: No profile or organization found');
      return null;
    }

    final organizationId = profileResponse['organization_id'] as String;
    final email = profileResponse['email'] as String?;

    // Try to get member by user_id first
    var memberResponse = await _client
        .from('members')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    // If not found by user_id, try by email
    if (memberResponse == null && email != null) {
      debugPrint('ProgramsRepository: No member by user_id, trying by email: $email');
      memberResponse = await _client
          .from('members')
          .select('id')
          .eq('email', email)
          .eq('organization_id', organizationId)
          .maybeSingle();
    }

    if (memberResponse == null) {
      debugPrint('ProgramsRepository: No member found');
      return null;
    }

    return (
      memberId: memberResponse['id'] as String,
      organizationId: organizationId,
    );
  }

  /// Get active program for member
  /// A program is: is_active=true, days_per_week NOT NULL, program_id IS NULL
  Future<Routine?> getActiveProgram() async {
    try {
      final context = await _getMemberContext();
      if (context == null) return null;

      debugPrint('ProgramsRepository: Finding active program for member ${context.memberId}');

      final response = await _client
          .from('workouts')
          .select()
          .eq('organization_id', context.organizationId)
          .eq('assigned_to_member_id', context.memberId)
          .eq('is_active', true)
          .not('days_per_week', 'is', null)
          .isFilter('program_id', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        debugPrint('ProgramsRepository: No active program found');
        return null;
      }

      debugPrint('ProgramsRepository: Found active program: ${response['name']}');
      return Routine.fromJson(response);
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting active program: $e');
      rethrow;
    }
  }

  /// Get all days for a program
  Future<List<Routine>> getProgramDays(String programId) async {
    try {
      debugPrint('ProgramsRepository: Fetching days for program $programId');

      final response = await _client
          .from('workouts')
          .select()
          .eq('program_id', programId)
          .order('day_number', ascending: true);

      final days = (response as List)
          .map((json) => Routine.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('ProgramsRepository: Found ${days.length} program days');
      return days;
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting program days: $e');
      rethrow;
    }
  }

  /// Get completion count for a program
  Future<int> getCompletionCount(String programId) async {
    try {
      final context = await _getMemberContext();
      if (context == null) return 0;

      // Get all day workout IDs for this program
      final daysResponse = await _client
          .from('workouts')
          .select('id')
          .eq('program_id', programId);

      final dayIds = (daysResponse as List)
          .map((d) => d['id'] as String)
          .toList();

      if (dayIds.isEmpty) return 0;

      // Count completions
      final completionsResponse = await _client
          .from('workout_completions')
          .select('id')
          .eq('member_id', context.memberId)
          .inFilter('workout_id', dayIds);

      final count = (completionsResponse as List).length;
      debugPrint('ProgramsRepository: Completion count for program $programId: $count');
      return count;
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting completion count: $e');
      return 0;
    }
  }

  /// Get today's workout following the web algorithm
  /// 1) Find active program
  /// 2) Count total completions
  /// 3) Calculate currentWeek and nextDayNumber
  /// 4) Fetch workout for that day
  /// 5) Check if already completed today
  Future<TodaysWorkout> getTodaysWorkout() async {
    try {
      final context = await _getMemberContext();
      if (context == null) {
        debugPrint('ProgramsRepository: No member context');
        return TodaysWorkout.empty();
      }

      // Step 1: Get active program
      final program = await getActiveProgram();
      if (program == null) {
        debugPrint('ProgramsRepository: No active program');
        return TodaysWorkout.empty();
      }

      // Step 2: Get all program days
      final days = await getProgramDays(program.id);
      if (days.isEmpty) {
        debugPrint('ProgramsRepository: No days in program');
        return TodaysWorkout.empty();
      }

      final dayIds = days.map((d) => d.id).toList();

      // Step 3: Count total completions
      final completionsResponse = await _client
          .from('workout_completions')
          .select('id, workout_id, completed_date')
          .eq('member_id', context.memberId)
          .inFilter('workout_id', dayIds);

      final totalCompletions = (completionsResponse as List).length;
      debugPrint('ProgramsRepository: Total completions: $totalCompletions');

      // Step 4: Calculate current position
      final daysPerWeek = program.daysPerWeek ?? _defaultDaysPerWeek;
      final totalWeeks = program.durationWeeks ?? _defaultDurationWeeks;

      final currentWeek = (totalCompletions ~/ daysPerWeek) + 1;
      final daysThisWeek = totalCompletions % daysPerWeek;
      final nextDayNumber = daysThisWeek + 1;

      debugPrint('ProgramsRepository: Week $currentWeek, day $nextDayNumber (daysThisWeek: $daysThisWeek)');

      // Check if program is complete
      if (currentWeek > totalWeeks) {
        debugPrint('ProgramsRepository: Program completed!');
        return TodaysWorkout(
          workout: null,
          progress: WeeklyProgress.calculate(
            totalCompletions: totalCompletions,
            daysPerWeek: daysPerWeek,
            durationWeeks: totalWeeks,
          ),
          program: ProgramInfo.fromRoutine(program),
          nextDayNumber: nextDayNumber,
          hasActiveProgram: true,
        );
      }

      // Step 5: Get workout for next day
      final todayWorkout = days.firstWhere(
        (d) => d.dayNumber == nextDayNumber,
        orElse: () => days.first,
      );

      // Step 6: Check if already completed today
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final isCompletedToday = (completionsResponse as List).any((c) {
        final completedDate = c['completed_date'] as String?;
        return completedDate == todayStr && c['workout_id'] == todayWorkout.id;
      });

      debugPrint('ProgramsRepository: Today workout: ${todayWorkout.name}, completed: $isCompletedToday');

      // Enrich workout with exercise details
      final enrichedWorkout = await _enrichWorkoutWithExercises(todayWorkout);

      return TodaysWorkout(
        workout: enrichedWorkout,
        progress: WeeklyProgress.calculate(
          totalCompletions: totalCompletions,
          daysPerWeek: daysPerWeek,
          durationWeeks: totalWeeks,
        ),
        program: ProgramInfo.fromRoutine(program),
        nextDayNumber: nextDayNumber,
        hasActiveProgram: true,
        isCompletedToday: isCompletedToday,
      );
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting todays workout: $e');
      rethrow;
    }
  }

  /// Complete a workout (idempotent - won't duplicate same day)
  Future<WorkoutCompletion?> completeWorkout(
    String workoutId, {
    int? durationMinutes,
    String? notes,
  }) async {
    try {
      final context = await _getMemberContext();
      if (context == null) {
        throw Exception('No hay sesión activa');
      }

      debugPrint('ProgramsRepository: Completing workout $workoutId');

      // Get workout info
      final workoutResponse = await _client
          .from('workouts')
          .select('id, program_id, organization_id')
          .eq('id', workoutId)
          .single();

      final programId = workoutResponse['program_id'] as String?;
      final orgId = workoutResponse['organization_id'] as String;

      // Calculate program_week if this is a program day
      int? programWeek;
      if (programId != null) {
        // Get all days in program
        final daysResponse = await _client
            .from('workouts')
            .select('id')
            .eq('program_id', programId);

        final dayIds = (daysResponse as List).map((d) => d['id'] as String).toList();

        // Get existing completions
        final completionsResponse = await _client
            .from('workout_completions')
            .select('id')
            .eq('member_id', context.memberId)
            .inFilter('workout_id', dayIds);

        final completionCount = (completionsResponse as List).length;

        // Get program's days_per_week
        final programResponse = await _client
            .from('workouts')
            .select('days_per_week')
            .eq('id', programId)
            .single();

        final daysPerWeek = programResponse['days_per_week'] as int? ?? _defaultDaysPerWeek;
        programWeek = (completionCount ~/ daysPerWeek) + 1;
      }

      // Get today's date
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Insert completion (unique constraint prevents duplicates)
      final insertResponse = await _client
          .from('workout_completions')
          .insert({
            'organization_id': orgId,
            'workout_id': workoutId,
            'member_id': context.memberId,
            'completed_date': todayStr,
            'program_week': programWeek,
            'duration_minutes': durationMinutes,
            'notes': notes,
          })
          .select()
          .single();

      debugPrint('ProgramsRepository: Workout completed successfully');
      return WorkoutCompletion.fromJson(insertResponse);
    } on PostgrestException catch (e) {
      // Handle unique constraint violation (already completed today)
      if (e.code == '23505') {
        debugPrint('ProgramsRepository: Workout already completed today');
        throw Exception('Ya completaste este entrenamiento hoy');
      }
      debugPrint('ProgramsRepository: Postgrest error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('ProgramsRepository: Error completing workout: $e');
      rethrow;
    }
  }

  /// Get weekly progress for a program
  Future<WeeklyProgress> getWeeklyProgress(String programId) async {
    try {
      // Get program details
      final programResponse = await _client
          .from('workouts')
          .select('days_per_week, duration_weeks')
          .eq('id', programId)
          .single();

      final daysPerWeek = programResponse['days_per_week'] as int? ?? _defaultDaysPerWeek;
      final totalWeeks = programResponse['duration_weeks'] as int? ?? _defaultDurationWeeks;

      // Get completion count
      final completionCount = await getCompletionCount(programId);

      return WeeklyProgress.calculate(
        totalCompletions: completionCount,
        daysPerWeek: daysPerWeek,
        durationWeeks: totalWeeks,
      );
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting weekly progress: $e');
      rethrow;
    }
  }

  /// Get overall program progress
  Future<ProgramProgress> getProgramProgress(String programId) async {
    try {
      // Get program details
      final programResponse = await _client
          .from('workouts')
          .select('days_per_week, duration_weeks')
          .eq('id', programId)
          .single();

      final daysPerWeek = programResponse['days_per_week'] as int? ?? _defaultDaysPerWeek;
      final totalWeeks = programResponse['duration_weeks'] as int? ?? _defaultDurationWeeks;

      // Get completion count
      final completionCount = await getCompletionCount(programId);

      return ProgramProgress.calculate(
        totalCompletions: completionCount,
        daysPerWeek: daysPerWeek,
        durationWeeks: totalWeeks,
      );
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting program progress: $e');
      rethrow;
    }
  }

  /// Get program days with completion status
  Future<List<ProgramDay>> getProgramDaysWithStatus(String programId) async {
    try {
      final context = await _getMemberContext();
      if (context == null) return [];

      // Get all days
      final days = await getProgramDays(programId);
      if (days.isEmpty) return [];

      final dayIds = days.map((d) => d.id).toList();

      // Get completions for these days
      final completionsResponse = await _client
          .from('workout_completions')
          .select('workout_id, completed_at')
          .eq('member_id', context.memberId)
          .inFilter('workout_id', dayIds);

      final completions = <String, DateTime>{};
      for (final c in (completionsResponse as List)) {
        completions[c['workout_id'] as String] =
            DateTime.parse(c['completed_at'] as String);
      }

      // Get program info
      final programResponse = await _client
          .from('workouts')
          .select('days_per_week')
          .eq('id', programId)
          .single();

      final daysPerWeek = programResponse['days_per_week'] as int? ?? _defaultDaysPerWeek;
      final totalCompletions = completions.length;
      final nextDayNumber = (totalCompletions % daysPerWeek) + 1;

      // Build list with status
      return days.map((workout) {
        final dayNum = workout.dayNumber ?? 0;
        final isCompleted = completions.containsKey(workout.id);
        final isNext = dayNum == nextDayNumber && !isCompleted;

        return ProgramDay(
          workout: workout,
          dayNumber: dayNum,
          isCompleted: isCompleted,
          isNext: isNext,
          completedAt: completions[workout.id],
        );
      }).toList();
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting days with status: $e');
      rethrow;
    }
  }

  /// Get workout by ID with exercise details
  Future<Routine?> getWorkoutById(String workoutId) async {
    try {
      final response = await _client
          .from('workouts')
          .select()
          .eq('id', workoutId)
          .maybeSingle();

      if (response == null) return null;

      final workout = Routine.fromJson(response);
      return _enrichWorkoutWithExercises(workout);
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting workout: $e');
      rethrow;
    }
  }

  /// Enrich a workout with full exercise details
  Future<Routine> _enrichWorkoutWithExercises(Routine workout) async {
    if (workout.exercises.isEmpty) return workout;

    try {
      final exerciseIds = workout.exercises.map((e) => e.exerciseId).toList();

      final response = await _client
          .from('exercises')
          .select()
          .inFilter('id', exerciseIds);

      final exerciseMap = <String, Map<String, dynamic>>{};
      for (final ex in (response as List)) {
        exerciseMap[ex['id'] as String] = ex as Map<String, dynamic>;
      }

      final enrichedExercises = workout.exercises.map((ex) {
        final details = exerciseMap[ex.exerciseId];
        if (details == null) return ex;

        return ExerciseItem(
          exerciseId: ex.exerciseId,
          exerciseName: ex.exerciseName,
          order: ex.order,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          restSeconds: ex.restSeconds,
          tempo: ex.tempo,
          notes: ex.notes,
          gifUrl: details['gif_url'] as String?,
          videoUrl: details['video_url'] as String?,
          thumbnailUrl: details['thumbnail_url'] as String?,
          category: details['category'] as String?,
          difficulty: details['difficulty'] as String?,
          muscleGroups: (details['muscle_groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
          instructions: _parseInstructions(details['instructions']),
        );
      }).toList();

      return Routine(
        id: workout.id,
        organizationId: workout.organizationId,
        name: workout.name,
        description: workout.description,
        workoutType: workout.workoutType,
        wodType: workout.wodType,
        wodTimeCap: workout.wodTimeCap,
        exercises: enrichedExercises,
        assignedToMemberId: workout.assignedToMemberId,
        assignedById: workout.assignedById,
        scheduledDate: workout.scheduledDate,
        isTemplate: workout.isTemplate,
        isActive: workout.isActive,
        createdAt: workout.createdAt,
        updatedAt: workout.updatedAt,
        memberName: workout.memberName,
        memberEmail: workout.memberEmail,
        programId: workout.programId,
        dayNumber: workout.dayNumber,
        durationWeeks: workout.durationWeeks,
        daysPerWeek: workout.daysPerWeek,
        programStartDate: workout.programStartDate,
      );
    } catch (e) {
      debugPrint('ProgramsRepository: Error enriching workout: $e');
      return workout;
    }
  }

  String? _parseInstructions(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) return raw.cast<String>().join('\n');
    if (raw is String) return raw;
    return null;
  }

  /// Get completion history for a program
  Future<List<WorkoutCompletion>> getCompletionHistory(String programId) async {
    try {
      final context = await _getMemberContext();
      if (context == null) return [];

      // Get all day IDs for program
      final daysResponse = await _client
          .from('workouts')
          .select('id')
          .eq('program_id', programId);

      final dayIds = (daysResponse as List).map((d) => d['id'] as String).toList();
      if (dayIds.isEmpty) return [];

      // Get completions
      final completionsResponse = await _client
          .from('workout_completions')
          .select()
          .eq('member_id', context.memberId)
          .inFilter('workout_id', dayIds)
          .order('completed_at', ascending: false);

      return (completionsResponse as List)
          .map((c) => WorkoutCompletion.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('ProgramsRepository: Error getting completion history: $e');
      return [];
    }
  }
}
