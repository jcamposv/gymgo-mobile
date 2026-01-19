import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/benchmarks_repository.dart';
import '../../domain/benchmark.dart';

/// Repository provider
final benchmarksRepositoryProvider = Provider<BenchmarksRepository>((ref) {
  return BenchmarksRepository(Supabase.instance.client);
});

/// Current PRs provider - fetches the best PR for each exercise
final currentPRsProvider = FutureProvider<List<CurrentPR>>((ref) async {
  final repository = ref.read(benchmarksRepositoryProvider);
  return repository.getCurrentPRs();
});

/// Parameters for history query
typedef BenchmarkHistoryParams = ({
  String? exerciseId,
  DateTime? dateFrom,
  DateTime? dateTo,
  int page,
  int pageSize,
});

/// Benchmark history provider with pagination
final benchmarkHistoryProvider = FutureProvider.family<
    ({List<ExerciseBenchmark> data, int total}), BenchmarkHistoryParams>(
  (ref, params) async {
    final repository = ref.read(benchmarksRepositoryProvider);
    return repository.getBenchmarkHistory(
      exerciseId: params.exerciseId,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      page: params.page,
      pageSize: params.pageSize,
    );
  },
);

/// Chart data provider for a specific exercise
final benchmarkChartDataProvider =
    FutureProvider.family<List<BenchmarkChartPoint>, String>((ref, exerciseId) async {
  final repository = ref.read(benchmarksRepositoryProvider);
  return repository.getChartData(exerciseId: exerciseId);
});

/// All benchmarks for a specific exercise (detail view)
final exerciseBenchmarksProvider =
    FutureProvider.family<List<ExerciseBenchmark>, String>((ref, exerciseId) async {
  final repository = ref.read(benchmarksRepositoryProvider);
  return repository.getExerciseBenchmarks(exerciseId);
});

/// Exercise options for picker
final exerciseOptionsProvider = FutureProvider<List<ExerciseOption>>((ref) async {
  final repository = ref.read(benchmarksRepositoryProvider);
  return repository.getExerciseOptions();
});

/// Single benchmark by ID
final benchmarkByIdProvider =
    FutureProvider.family<ExerciseBenchmark?, String>((ref, benchmarkId) async {
  final repository = ref.read(benchmarksRepositoryProvider);
  return repository.getBenchmarkById(benchmarkId);
});

/// State notifier for benchmark actions (create, update, delete)
class BenchmarkActionsNotifier extends StateNotifier<AsyncValue<void>> {
  BenchmarkActionsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  final BenchmarksRepository _repository;
  final Ref _ref;

  /// Create a new benchmark
  Future<ExerciseBenchmark?> createBenchmark(BenchmarkFormData formData) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createBenchmark(formData);

      // Invalidate relevant providers to refresh data
      _ref.invalidate(currentPRsProvider);
      _ref.invalidate(exerciseBenchmarksProvider(formData.exerciseId));
      _ref.invalidate(benchmarkChartDataProvider(formData.exerciseId));

      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update an existing benchmark
  Future<ExerciseBenchmark?> updateBenchmark(
    String benchmarkId,
    BenchmarkFormData formData,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateBenchmark(benchmarkId, formData);

      // Invalidate relevant providers
      _ref.invalidate(currentPRsProvider);
      _ref.invalidate(exerciseBenchmarksProvider(formData.exerciseId));
      _ref.invalidate(benchmarkChartDataProvider(formData.exerciseId));
      _ref.invalidate(benchmarkByIdProvider(benchmarkId));

      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Delete a benchmark
  Future<bool> deleteBenchmark(String benchmarkId, String exerciseId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBenchmark(benchmarkId);

      // Invalidate relevant providers
      _ref.invalidate(currentPRsProvider);
      _ref.invalidate(exerciseBenchmarksProvider(exerciseId));
      _ref.invalidate(benchmarkChartDataProvider(exerciseId));

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for benchmark actions
final benchmarkActionsProvider =
    StateNotifierProvider<BenchmarkActionsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.read(benchmarksRepositoryProvider);
  return BenchmarkActionsNotifier(repository, ref);
});

/// Search/filter state for PRs screen
class PRsFilterState {
  const PRsFilterState({
    this.searchQuery = '',
    this.selectedExerciseId,
    this.dateFrom,
    this.dateTo,
    this.currentPage = 1,
    this.pageSize = 10,
    this.activeTab = 0, // 0 = Current, 1 = History
  });

  final String searchQuery;
  final String? selectedExerciseId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int currentPage;
  final int pageSize;
  final int activeTab;

  PRsFilterState copyWith({
    String? searchQuery,
    String? selectedExerciseId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? currentPage,
    int? pageSize,
    int? activeTab,
    bool clearExerciseId = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return PRsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedExerciseId: clearExerciseId ? null : (selectedExerciseId ?? this.selectedExerciseId),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

/// State notifier for PRs filter
class PRsFilterNotifier extends StateNotifier<PRsFilterState> {
  PRsFilterNotifier() : super(const PRsFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedExercise(String? exerciseId) {
    if (exerciseId == null) {
      state = state.copyWith(clearExerciseId: true, currentPage: 1);
    } else {
      state = state.copyWith(selectedExerciseId: exerciseId, currentPage: 1);
    }
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      dateFrom: from,
      dateTo: to,
      clearDateFrom: from == null,
      clearDateTo: to == null,
      currentPage: 1,
    );
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void setActiveTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  void reset() {
    state = const PRsFilterState();
  }
}

/// Provider for PRs filter state
final prsFilterProvider = StateNotifierProvider<PRsFilterNotifier, PRsFilterState>((ref) {
  return PRsFilterNotifier();
});

/// Filtered current PRs based on search query
final filteredCurrentPRsProvider = FutureProvider<List<CurrentPR>>((ref) async {
  final filter = ref.watch(prsFilterProvider);
  final prs = await ref.watch(currentPRsProvider.future);

  if (filter.searchQuery.isEmpty) {
    return prs;
  }

  final query = filter.searchQuery.toLowerCase();
  return prs.where((pr) {
    return pr.exerciseName.toLowerCase().contains(query) ||
        (pr.exerciseCategory?.toLowerCase().contains(query) ?? false);
  }).toList();
});
