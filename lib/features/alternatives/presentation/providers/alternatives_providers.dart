import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/alternatives_repository.dart';
import '../../domain/exercise_alternative.dart';

/// Repository provider
final alternativesRepositoryProvider = Provider<AlternativesRepository>((ref) {
  final repository = AlternativesRepository();
  ref.onDispose(() => repository.dispose());
  return repository;
});

/// Parameters for alternatives query
typedef AlternativesParams = ({
  String exerciseId,
  String? difficultyFilter,
  int limit,
});

/// Helper to create params
AlternativesParams alternativesParams({
  required String exerciseId,
  String? difficultyFilter,
  int limit = 5,
}) {
  return (
    exerciseId: exerciseId,
    difficultyFilter: difficultyFilter,
    limit: limit,
  );
}

/// Provider for exercise alternatives
final exerciseAlternativesProvider =
    FutureProvider.family<AlternativesResponse, AlternativesParams>(
  (ref, params) async {
    final repository = ref.watch(alternativesRepositoryProvider);
    return repository.getAlternatives(
      exerciseId: params.exerciseId,
      difficultyFilter: params.difficultyFilter,
      limit: params.limit,
    );
  },
);

/// Simplified provider that just takes exerciseId (most common use case)
final simpleAlternativesProvider =
    FutureProvider.family<AlternativesResponse, String>(
  (ref, exerciseId) async {
    final repository = ref.watch(alternativesRepositoryProvider);
    return repository.getAlternatives(
      exerciseId: exerciseId,
      limit: 5,
    );
  },
);
