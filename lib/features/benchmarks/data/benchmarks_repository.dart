import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/benchmark.dart';

/// Repository for managing exercise benchmarks/PRs from Supabase
/// Mirrors web: src/actions/benchmark.actions.ts
class BenchmarksRepository {
  BenchmarksRepository(this._client);

  final SupabaseClient _client;

  /// Get member info from current user
  Future<({String memberId, String organizationId})?> _getMemberInfo() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('members')
        .select('id, organization_id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return (
      memberId: response['id'] as String,
      organizationId: response['organization_id'] as String,
    );
  }

  /// Get current PRs for the logged-in member
  /// Returns the most recent PR for each exercise (where is_pr = true)
  Future<List<CurrentPR>> getCurrentPRs() async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) {
        debugPrint('BenchmarksRepository: No member found');
        return [];
      }

      debugPrint('BenchmarksRepository: Fetching current PRs for member ${memberInfo.memberId}');

      final response = await _client
          .from('exercise_benchmarks')
          .select('''
            id,
            member_id,
            organization_id,
            exercise_id,
            value,
            unit,
            reps,
            achieved_at,
            is_pr,
            exercises (
              id,
              name,
              name_es,
              category,
              gif_url
            )
          ''')
          .eq('member_id', memberInfo.memberId)
          .eq('organization_id', memberInfo.organizationId)
          .eq('is_pr', true)
          .order('achieved_at', ascending: false);

      debugPrint('BenchmarksRepository: Got ${(response as List).length} PR entries');

      // Parse and dedupe - keep only the most recent PR per exercise
      final benchmarks = (response as List)
          .map((json) => ExerciseBenchmark.fromJson(json))
          .toList();

      final prsByExercise = <String, ExerciseBenchmark>{};
      for (final benchmark in benchmarks) {
        if (!prsByExercise.containsKey(benchmark.exerciseId)) {
          prsByExercise[benchmark.exerciseId] = benchmark;
        }
      }

      return prsByExercise.values
          .map((b) => CurrentPR.fromBenchmark(b))
          .toList();
    } catch (e) {
      debugPrint('BenchmarksRepository: Error fetching current PRs: $e');
      rethrow;
    }
  }

  /// Get paginated benchmark history for a member
  Future<({List<ExerciseBenchmark> data, int total})> getBenchmarkHistory({
    String? exerciseId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 10,
    String sortBy = 'achieved_at',
    bool ascending = false,
  }) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) {
        return (data: <ExerciseBenchmark>[], total: 0);
      }

      debugPrint('BenchmarksRepository: Fetching history page $page');

      var query = _client
          .from('exercise_benchmarks')
          .select('''
            *,
            exercises (
              id,
              name,
              name_es,
              category,
              gif_url
            )
          ''')
          .eq('member_id', memberInfo.memberId)
          .eq('organization_id', memberInfo.organizationId);

      // Apply filters
      if (exerciseId != null) {
        query = query.eq('exercise_id', exerciseId);
      }
      if (dateFrom != null) {
        query = query.gte('achieved_at', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('achieved_at', dateTo.toIso8601String());
      }

      // Get total count first
      final countQuery = _client
          .from('exercise_benchmarks')
          .select()
          .eq('member_id', memberInfo.memberId)
          .eq('organization_id', memberInfo.organizationId);

      if (exerciseId != null) {
        countQuery.eq('exercise_id', exerciseId);
      }

      final countResponse = await countQuery;
      final total = (countResponse as List).length;

      // Apply pagination and sorting
      final offset = (page - 1) * pageSize;
      final response = await query
          .order(sortBy, ascending: ascending)
          .range(offset, offset + pageSize - 1);

      final benchmarks = (response as List)
          .map((json) => ExerciseBenchmark.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('BenchmarksRepository: Got ${benchmarks.length} entries (total: $total)');

      return (data: benchmarks, total: total);
    } catch (e) {
      debugPrint('BenchmarksRepository: Error fetching history: $e');
      rethrow;
    }
  }

  /// Get chart data for a specific exercise (time series)
  Future<List<BenchmarkChartPoint>> getChartData({
    required String exerciseId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
  }) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) return [];

      debugPrint('BenchmarksRepository: Fetching chart data for exercise $exerciseId');

      var query = _client
          .from('exercise_benchmarks')
          .select('achieved_at, value, is_pr')
          .eq('member_id', memberInfo.memberId)
          .eq('organization_id', memberInfo.organizationId)
          .eq('exercise_id', exerciseId);

      if (dateFrom != null) {
        query = query.gte('achieved_at', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('achieved_at', dateTo.toIso8601String());
      }

      // Order ascending for chart progression (oldest first)
      var response = await query.order('achieved_at', ascending: true);

      if (limit != null && (response as List).length > limit) {
        response = response.take(limit).toList();
      }

      return (response as List)
          .map((json) => BenchmarkChartPoint.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('BenchmarksRepository: Error fetching chart data: $e');
      rethrow;
    }
  }

  /// Get all benchmarks for a specific exercise (for detail view)
  Future<List<ExerciseBenchmark>> getExerciseBenchmarks(String exerciseId) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) return [];

      final response = await _client
          .from('exercise_benchmarks')
          .select('''
            *,
            exercises (
              id,
              name,
              name_es,
              category,
              gif_url
            )
          ''')
          .eq('member_id', memberInfo.memberId)
          .eq('organization_id', memberInfo.organizationId)
          .eq('exercise_id', exerciseId)
          .order('achieved_at', ascending: false);

      return (response as List)
          .map((json) => ExerciseBenchmark.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('BenchmarksRepository: Error fetching exercise benchmarks: $e');
      rethrow;
    }
  }

  /// Create a new benchmark entry
  Future<ExerciseBenchmark> createBenchmark(BenchmarkFormData formData) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) {
        throw Exception('No member found for current user');
      }

      final user = _client.auth.currentUser!;

      debugPrint('BenchmarksRepository: Creating benchmark for exercise ${formData.exerciseId}');

      final payload = {
        'member_id': memberInfo.memberId,
        'organization_id': memberInfo.organizationId,
        'recorded_by_id': user.id,
        ...formData.toJson(),
      };

      final response = await _client
          .from('exercise_benchmarks')
          .insert(payload)
          .select('''
            *,
            exercises (
              id,
              name,
              name_es,
              category,
              gif_url
            )
          ''')
          .single();

      debugPrint('BenchmarksRepository: Benchmark created successfully');

      return ExerciseBenchmark.fromJson(response);
    } catch (e) {
      debugPrint('BenchmarksRepository: Error creating benchmark: $e');
      rethrow;
    }
  }

  /// Update an existing benchmark
  Future<ExerciseBenchmark> updateBenchmark(
    String benchmarkId,
    BenchmarkFormData formData,
  ) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) {
        throw Exception('No member found for current user');
      }

      debugPrint('BenchmarksRepository: Updating benchmark $benchmarkId');

      final response = await _client
          .from('exercise_benchmarks')
          .update(formData.toJson())
          .eq('id', benchmarkId)
          .eq('organization_id', memberInfo.organizationId)
          .select('''
            *,
            exercises (
              id,
              name,
              name_es,
              category,
              gif_url
            )
          ''')
          .single();

      debugPrint('BenchmarksRepository: Benchmark updated successfully');

      return ExerciseBenchmark.fromJson(response);
    } catch (e) {
      debugPrint('BenchmarksRepository: Error updating benchmark: $e');
      rethrow;
    }
  }

  /// Delete a benchmark entry
  Future<void> deleteBenchmark(String benchmarkId) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) {
        throw Exception('No member found for current user');
      }

      debugPrint('BenchmarksRepository: Deleting benchmark $benchmarkId');

      await _client
          .from('exercise_benchmarks')
          .delete()
          .eq('id', benchmarkId)
          .eq('organization_id', memberInfo.organizationId);

      debugPrint('BenchmarksRepository: Benchmark deleted successfully');
    } catch (e) {
      debugPrint('BenchmarksRepository: Error deleting benchmark: $e');
      rethrow;
    }
  }

  /// Get exercises for benchmark dropdown/picker
  Future<List<ExerciseOption>> getExerciseOptions() async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) return [];

      debugPrint('BenchmarksRepository: Fetching exercise options');

      // Get exercises that belong to the organization OR are global
      final response = await _client
          .from('exercises')
          .select('id, name, name_es, category')
          .or('organization_id.eq.${memberInfo.organizationId},is_global.eq.true')
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => ExerciseOption.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('BenchmarksRepository: Error fetching exercise options: $e');
      rethrow;
    }
  }

  /// Get a single benchmark by ID
  Future<ExerciseBenchmark?> getBenchmarkById(String benchmarkId) async {
    try {
      final memberInfo = await _getMemberInfo();
      if (memberInfo == null) return null;

      final response = await _client
          .from('exercise_benchmarks')
          .select('''
            *,
            exercises (
              id,
              name,
              name_es,
              category,
              gif_url
            )
          ''')
          .eq('id', benchmarkId)
          .eq('organization_id', memberInfo.organizationId)
          .maybeSingle();

      if (response == null) return null;

      return ExerciseBenchmark.fromJson(response);
    } catch (e) {
      debugPrint('BenchmarksRepository: Error fetching benchmark: $e');
      rethrow;
    }
  }
}
