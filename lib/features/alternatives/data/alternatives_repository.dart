import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../domain/exercise_alternative.dart';

/// Repository for fetching AI exercise alternatives
class AlternativesRepository {
  final ApiClient _apiClient;

  AlternativesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get alternatives for an exercise
  Future<AlternativesResponse> getAlternatives({
    required String exerciseId,
    String? difficultyFilter,
    int limit = 5,
  }) async {
    final request = AlternativesRequest(
      exerciseId: exerciseId,
      difficultyFilter: difficultyFilter,
      limit: limit,
    );

    final response = await _apiClient.post(
      '/ai/alternatives',
      request.toJson(),
    );

    // Debug: Log the raw response to see remaining_requests
    debugPrint('AlternativesRepository: Raw API response: $response');
    if (response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      debugPrint('AlternativesRepository: remaining_requests = ${data['remaining_requests']}');
    }

    return AlternativesResponse.fromJson(response);
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
}
