/// Domain models for AI Exercise Alternatives

/// Exercise data returned in alternatives
class AlternativeExercise {
  final String id;
  final String name;
  final String? nameEs;
  final String? category;
  final List<String>? muscleGroups;
  final List<String>? equipment;
  final String? difficulty;
  final String? gifUrl;
  final String? movementPattern;

  AlternativeExercise({
    required this.id,
    required this.name,
    this.nameEs,
    this.category,
    this.muscleGroups,
    this.equipment,
    this.difficulty,
    this.gifUrl,
    this.movementPattern,
  });

  factory AlternativeExercise.fromJson(Map<String, dynamic> json) {
    return AlternativeExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEs: json['name_es'] as String?,
      category: json['category'] as String?,
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipment: (json['equipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      difficulty: json['difficulty'] as String?,
      gifUrl: json['gif_url'] as String?,
      movementPattern: json['movement_pattern'] as String?,
    );
  }

  /// Get display name (Spanish preferred)
  String get displayName => nameEs ?? name;
}

/// Exercise alternative with score and reason
class ExerciseAlternative {
  final AlternativeExercise exercise;
  final String reason;
  final int score;

  ExerciseAlternative({
    required this.exercise,
    required this.reason,
    required this.score,
  });

  factory ExerciseAlternative.fromJson(Map<String, dynamic> json) {
    return ExerciseAlternative(
      exercise: AlternativeExercise.fromJson(
          json['exercise'] as Map<String, dynamic>),
      reason: json['reason'] as String,
      score: (json['score'] as num).toInt(),
    );
  }
}

/// Full API response
class AlternativesResponse {
  final List<ExerciseAlternative> alternatives;
  final bool wasCached;
  final int tokensUsed;
  final int remainingRequests;

  AlternativesResponse({
    required this.alternatives,
    required this.wasCached,
    required this.tokensUsed,
    required this.remainingRequests,
  });

  factory AlternativesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AlternativesResponse(
      alternatives: (data['alternatives'] as List<dynamic>)
          .map((e) => ExerciseAlternative.fromJson(e as Map<String, dynamic>))
          .toList(),
      wasCached: data['was_cached'] as bool,
      tokensUsed: (data['tokens_used'] as num).toInt(),
      remainingRequests: (data['remaining_requests'] as num).toInt(),
    );
  }
}

/// Request parameters
class AlternativesRequest {
  final String exerciseId;
  final String? difficultyFilter;
  final int limit;

  AlternativesRequest({
    required this.exerciseId,
    this.difficultyFilter,
    this.limit = 5,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'exercise_id': exerciseId,
      'limit': limit,
    };
    if (difficultyFilter != null) {
      json['difficulty_filter'] = difficultyFilter;
    }
    return json;
  }
}
