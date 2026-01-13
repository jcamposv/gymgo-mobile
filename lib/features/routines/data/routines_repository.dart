import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/routine.dart';

/// Repository for managing routines from Supabase
/// Mirrors web API: routine.actions.ts
class RoutinesRepository {
  RoutinesRepository(this._client);

  final SupabaseClient _client;

  /// Get all routines assigned to the current member
  /// This is the main method for mobile users to see their routines
  Future<List<Routine>> getMyRoutines() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('RoutinesRepository: No authenticated user');
        return [];
      }

      debugPrint('RoutinesRepository: Fetching routines for user: ${user.id}');

      // First get the member record for this user
      final memberResponse = await _client
          .from('members')
          .select('id, organization_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberResponse == null) {
        debugPrint('RoutinesRepository: No member found for user');
        return [];
      }

      final memberId = memberResponse['id'] as String;
      final organizationId = memberResponse['organization_id'] as String;

      debugPrint('RoutinesRepository: Found member: $memberId, org: $organizationId');

      // Fetch routines assigned to this member
      final response = await _client
          .from('workouts')
          .select()
          .eq('assigned_to_member_id', memberId)
          .eq('organization_id', organizationId)
          .eq('is_active', true)
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
  Future<Routine?> getRoutineById(String routineId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      debugPrint('RoutinesRepository: Fetching routine: $routineId');

      // Get member info first
      final memberResponse = await _client
          .from('members')
          .select('id, organization_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberResponse == null) return null;

      final memberId = memberResponse['id'] as String;
      final organizationId = memberResponse['organization_id'] as String;

      // Fetch the routine (must be assigned to this member)
      final response = await _client
          .from('workouts')
          .select()
          .eq('id', routineId)
          .eq('assigned_to_member_id', memberId)
          .eq('organization_id', organizationId)
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

      // Get organization from member
      final memberResponse = await _client
          .from('members')
          .select('organization_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberResponse == null) return [];

      final organizationId = memberResponse['organization_id'] as String;

      var query = _client
          .from('workouts')
          .select()
          .eq('organization_id', organizationId)
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

  /// Enrich routines with full exercise details (gif, video, instructions)
  Future<List<Routine>> _enrichRoutinesWithExerciseDetails(List<Routine> routines) async {
    if (routines.isEmpty) return routines;

    // Collect all unique exercise IDs
    final exerciseIds = <String>{};
    for (final routine in routines) {
      for (final ex in routine.exercises) {
        exerciseIds.add(ex.exerciseId);
      }
    }

    if (exerciseIds.isEmpty) return routines;

    // Fetch exercise details
    final exerciseDetails = await getExerciseDetails(exerciseIds.toList());

    // Enrich each routine's exercises with details
    return routines.map((routine) {
      final enrichedExercises = routine.exercises.map((ex) {
        final details = exerciseDetails[ex.exerciseId];
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
          gifUrl: details.gifUrl,
          videoUrl: details.videoUrl,
          thumbnailUrl: details.thumbnailUrl,
          category: details.category,
          difficulty: details.difficulty,
          muscleGroups: details.muscleGroups,
          instructions: details.instructions,
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
}
