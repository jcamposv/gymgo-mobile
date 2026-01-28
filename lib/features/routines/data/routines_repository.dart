import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/routine.dart';

/// Repository for managing routines from Supabase
/// Mirrors web API: routine.actions.ts
class RoutinesRepository {
  RoutinesRepository(this._client);

  final SupabaseClient _client;

  /// Get user context from profiles (works for ALL users including admin)
  /// Returns organizationId and optional memberId
  /// Tries to find member by user_id first, then by email if not found
  Future<({String organizationId, String? memberId})?> _getUserContext() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // Get organization and email from profile (works for ALL users)
    final profileResponse = await _client
        .from('profiles')
        .select('organization_id, email')
        .eq('id', user.id)
        .maybeSingle();

    if (profileResponse == null || profileResponse['organization_id'] == null) {
      debugPrint('RoutinesRepository: No profile or organization found');
      return null;
    }

    final organizationId = profileResponse['organization_id'] as String;
    final email = profileResponse['email'] as String?;

    // Try to get member ID by user_id first
    var memberResponse = await _client
        .from('members')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    // If not found by user_id, try by email (for members created before account linking)
    if (memberResponse == null && email != null) {
      debugPrint('RoutinesRepository: No member by user_id, trying by email: $email');
      memberResponse = await _client
          .from('members')
          .select('id')
          .eq('email', email)
          .eq('organization_id', organizationId)
          .maybeSingle();
    }

    final memberId = memberResponse?['id'] as String?;

    debugPrint('RoutinesRepository: Context - org: $organizationId, member: $memberId, email: $email');

    return (organizationId: organizationId, memberId: memberId);
  }

  /// Get all routines assigned to the current user
  /// "Mis Rutinas" always shows only routines assigned to the current member
  /// (regardless of whether they're admin or not - admin can also train)
  Future<List<Routine>> getMyRoutines() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('RoutinesRepository: No authenticated user');
        return [];
      }

      debugPrint('RoutinesRepository: Fetching routines for user: ${user.id}');

      final context = await _getUserContext();
      if (context == null) {
        debugPrint('RoutinesRepository: No user context found');
        return [];
      }

      // If user doesn't have a member record, they can't have assigned routines
      if (context.memberId == null) {
        debugPrint('RoutinesRepository: No member record - no assigned routines');
        return [];
      }

      // Get routines assigned to this member
      // Exclude program child records (they're accessed via their parent program)
      // Only show parent programs and standalone routines (WEB contract: .is('program_id', null))
      final response = await _client
          .from('workouts')
          .select()
          .eq('assigned_to_member_id', context.memberId!)
          .eq('organization_id', context.organizationId)
          .eq('is_active', true)
          .isFilter('program_id', null)  // Only parent programs and standalone routines
          .order('scheduled_date', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);

      debugPrint('RoutinesRepository: Got ${(response as List).length} routines');

      final routines = response
          .map((json) => Routine.fromJson(json as Map<String, dynamic>))
          .toList();

      // Enrich with exercise details
      return _enrichRoutinesWithExerciseDetails(routines);
    } catch (e) {
      debugPrint('RoutinesRepository: Error fetching my routines: $e');
      rethrow;
    }
  }

  /// Get a single routine by ID with full exercise details
  /// User can access their own assigned routines within their org
  Future<Routine?> getRoutineById(String routineId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      debugPrint('RoutinesRepository: Fetching routine: $routineId');

      final context = await _getUserContext();
      if (context == null || context.memberId == null) return null;

      // Fetch the routine (must be assigned to this member)
      final response = await _client
          .from('workouts')
          .select()
          .eq('id', routineId)
          .eq('assigned_to_member_id', context.memberId!)
          .eq('organization_id', context.organizationId)
          .maybeSingle();

      if (response == null) {
        debugPrint('RoutinesRepository: Routine not found or not accessible');
        return null;
      }

      final routine = Routine.fromJson(response);

      // Enrich with exercise details
      final enriched = await _enrichRoutinesWithExerciseDetails([routine]);
      return enriched.isNotEmpty ? enriched.first : routine;
    } catch (e) {
      debugPrint('RoutinesRepository: Error fetching routine: $e');
      rethrow;
    }
  }

  /// Get all template routines (for browsing available routines)
  Future<List<Routine>> getTemplateRoutines({
    WorkoutType? workoutType,
    String? searchQuery,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      // Get organization from context (works for both admin and members)
      final context = await _getUserContext();
      if (context == null) return [];

      var query = _client
          .from('workouts')
          .select()
          .eq('organization_id', context.organizationId)
          .eq('is_template', true)
          .eq('is_active', true);

      if (workoutType != null) {
        query = query.eq('workout_type', workoutType.value);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      final response = await query.order('name', ascending: true);

      return (response as List)
          .map((json) => Routine.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('RoutinesRepository: Error fetching templates: $e');
      rethrow;
    }
  }

  /// Get exercise details by IDs
  Future<Map<String, Exercise>> getExerciseDetails(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return {};

    try {
      debugPrint('RoutinesRepository: Fetching ${exerciseIds.length} exercises: $exerciseIds');

      final response = await _client
          .from('exercises')
          .select()
          .inFilter('id', exerciseIds);

      debugPrint('RoutinesRepository: Got ${(response as List).length} exercises from DB');

      final exercises = <String, Exercise>{};
      for (final json in response) {
        try {
          final exercise = Exercise.fromJson(json as Map<String, dynamic>);
          exercises[exercise.id] = exercise;

          // Debug media URLs
          if (exercise.gifUrl != null || exercise.videoUrl != null) {
            debugPrint('RoutinesRepository: Exercise ${exercise.name} has media - gif: ${exercise.gifUrl != null}, video: ${exercise.videoUrl != null}');
          }
        } catch (parseError) {
          debugPrint('RoutinesRepository: Error parsing exercise: $parseError');
          debugPrint('RoutinesRepository: Raw JSON: $json');
        }
      }

      debugPrint('RoutinesRepository: Successfully parsed ${exercises.length} exercises');
      return exercises;
    } catch (e, stackTrace) {
      debugPrint('RoutinesRepository: Error fetching exercises: $e');
      debugPrint('RoutinesRepository: Stack trace: $stackTrace');
      return {};
    }
  }

  /// Substitute an exercise for today only
  /// Uses the database function to create/update an override
  Future<void> substituteExercise({
    required String workoutId,
    required String originalExerciseId,
    required int exerciseOrder,
    required String replacementExerciseId,
    String? reason,
  }) async {
    try {
      debugPrint('RoutinesRepository: Substituting exercise in workout $workoutId');
      debugPrint('RoutinesRepository: Original: $originalExerciseId, Replacement: $replacementExerciseId');

      final response = await _client.rpc('substitute_exercise', params: {
        'p_workout_id': workoutId,
        'p_original_exercise_id': originalExerciseId,
        'p_original_exercise_order': exerciseOrder,
        'p_replacement_exercise_id': replacementExerciseId,
        'p_reason': reason,
      });

      final result = response as Map<String, dynamic>?;

      if (result == null || result['success'] != true) {
        final error = result?['error'] ?? 'Unknown error';
        throw Exception('Failed to substitute exercise: $error');
      }

      debugPrint('RoutinesRepository: Exercise substituted successfully');
    } catch (e) {
      debugPrint('RoutinesRepository: Error substituting exercise: $e');
      rethrow;
    }
  }

  /// Enrich routines with full exercise details (gif, video, instructions)
  /// Also applies daily overrides for today's date
  Future<List<Routine>> _enrichRoutinesWithExerciseDetails(List<Routine> routines) async {
    if (routines.isEmpty) return routines;

    // Collect all unique exercise IDs
    final exerciseIds = <String>{};
    for (final routine in routines) {
      for (final ex in routine.exercises) {
        exerciseIds.add(ex.exerciseId);
      }
    }

    // Fetch overrides for all routines for today
    final overridesMap = await _fetchTodayOverrides(routines.map((r) => r.id).toList());

    // Also collect replacement exercise IDs from overrides
    for (final overrides in overridesMap.values) {
      for (final override in overrides) {
        exerciseIds.add(override['replacement_exercise_id'] as String);
      }
    }

    if (exerciseIds.isEmpty) return routines;

    // Fetch exercise details
    final exerciseDetails = await getExerciseDetails(exerciseIds.toList());

    // Enrich each routine's exercises with details and apply overrides
    return routines.map((routine) {
      final routineOverrides = overridesMap[routine.id] ?? [];

      final enrichedExercises = routine.exercises.map((ex) {
        // Check if this exercise has an override for today
        final override = routineOverrides.firstWhere(
          (o) => o['original_exercise_order'] == ex.order,
          orElse: () => <String, dynamic>{},
        );

        String exerciseId = ex.exerciseId;
        String exerciseName = ex.exerciseName;
        bool isOverridden = false;

        if (override.isNotEmpty) {
          // Use the replacement exercise
          exerciseId = override['replacement_exercise_id'] as String;
          exerciseName = (override['replacement_name_es'] as String?) ??
              (override['replacement_name'] as String?) ??
              exerciseName;
          isOverridden = true;
          debugPrint('RoutinesRepository: Exercise at order ${ex.order} overridden with $exerciseName');
        }

        final details = exerciseDetails[exerciseId];

        return ExerciseItem(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          order: ex.order,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          restSeconds: ex.restSeconds,
          tempo: ex.tempo,
          notes: isOverridden ? '(Reemplazado por hoy) ${ex.notes ?? ""}' : ex.notes,
          gifUrl: isOverridden
              ? (override['replacement_gif_url'] as String?)
              : details?.gifUrl,
          videoUrl: details?.videoUrl,
          thumbnailUrl: details?.thumbnailUrl,
          category: isOverridden
              ? (override['replacement_category'] as String?)
              : details?.category,
          difficulty: isOverridden
              ? (override['replacement_difficulty'] as String?)
              : details?.difficulty,
          muscleGroups: isOverridden
              ? (override['replacement_muscle_groups'] as List<dynamic>?)?.cast<String>()
              : details?.muscleGroups,
          instructions: details?.instructions,
        );
      }).toList();

      return Routine(
        id: routine.id,
        organizationId: routine.organizationId,
        name: routine.name,
        description: routine.description,
        workoutType: routine.workoutType,
        wodType: routine.wodType,
        wodTimeCap: routine.wodTimeCap,
        exercises: enrichedExercises,
        assignedToMemberId: routine.assignedToMemberId,
        assignedById: routine.assignedById,
        scheduledDate: routine.scheduledDate,
        isTemplate: routine.isTemplate,
        isActive: routine.isActive,
        createdAt: routine.createdAt,
        updatedAt: routine.updatedAt,
        memberName: routine.memberName,
        memberEmail: routine.memberEmail,
      );
    }).toList();
  }

  /// Fetch today's overrides for given workout IDs
  Future<Map<String, List<Map<String, dynamic>>>> _fetchTodayOverrides(
    List<String> workoutIds,
  ) async {
    if (workoutIds.isEmpty) return {};

    try {
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      debugPrint('RoutinesRepository: Fetching overrides for $todayStr');

      final response = await _client
          .from('workout_exercise_overrides')
          .select('''
            workout_id,
            original_exercise_order,
            original_exercise_id,
            replacement_exercise_id,
            reason,
            exercises!workout_exercise_overrides_replacement_exercise_id_fkey (
              name,
              name_es,
              gif_url,
              category,
              difficulty,
              muscle_groups
            )
          ''')
          .inFilter('workout_id', workoutIds)
          .eq('override_date', todayStr)
          .eq('is_active', true);

      final overridesMap = <String, List<Map<String, dynamic>>>{};

      for (final row in (response as List)) {
        final workoutId = row['workout_id'] as String;
        final exercise = row['exercises'] as Map<String, dynamic>?;

        final override = {
          'original_exercise_order': row['original_exercise_order'],
          'original_exercise_id': row['original_exercise_id'],
          'replacement_exercise_id': row['replacement_exercise_id'],
          'reason': row['reason'],
          'replacement_name': exercise?['name'],
          'replacement_name_es': exercise?['name_es'],
          'replacement_gif_url': exercise?['gif_url'],
          'replacement_category': exercise?['category'],
          'replacement_difficulty': exercise?['difficulty'],
          'replacement_muscle_groups': exercise?['muscle_groups'],
        };

        overridesMap.putIfAbsent(workoutId, () => []).add(override);
      }

      debugPrint('RoutinesRepository: Found ${overridesMap.length} workouts with overrides');
      return overridesMap;
    } catch (e) {
      debugPrint('RoutinesRepository: Error fetching overrides: $e');
      return {};
    }
  }
}
