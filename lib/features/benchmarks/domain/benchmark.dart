/// Benchmark domain models
/// Mirrors web: src/types/benchmark.types.ts

/// Benchmark unit enum - matches web/database
enum BenchmarkUnit {
  kg('kg'),
  lbs('lbs'),
  reps('reps'),
  seconds('seconds'),
  minutes('minutes'),
  meters('meters'),
  calories('calories'),
  rounds('rounds');

  const BenchmarkUnit(this.value);
  final String value;

  static BenchmarkUnit fromString(String value) {
    return BenchmarkUnit.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BenchmarkUnit.kg,
    );
  }

  /// Units where lower is better (time-based)
  bool get isTimeBased => this == seconds || this == minutes;

  /// Display label for UI
  String get displayLabel {
    switch (this) {
      case kg:
        return 'kg';
      case lbs:
        return 'lbs';
      case reps:
        return 'reps';
      case seconds:
        return 'seg';
      case minutes:
        return 'min';
      case meters:
        return 'm';
      case calories:
        return 'cal';
      case rounds:
        return 'rondas';
    }
  }
}

/// Exercise Benchmark entry from Supabase
class ExerciseBenchmark {
  const ExerciseBenchmark({
    required this.id,
    required this.memberId,
    required this.organizationId,
    required this.exerciseId,
    required this.value,
    required this.unit,
    this.reps,
    this.sets,
    this.rpe,
    required this.achievedAt,
    this.notes,
    required this.isPr,
    this.recordedById,
    required this.createdAt,
    required this.updatedAt,
    this.exercise,
  });

  final String id;
  final String memberId;
  final String organizationId;
  final String exerciseId;
  final double value;
  final BenchmarkUnit unit;
  final int? reps;
  final int? sets;
  final double? rpe;
  final DateTime achievedAt;
  final String? notes;
  final bool isPr;
  final String? recordedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BenchmarkExercise? exercise;

  factory ExerciseBenchmark.fromJson(Map<String, dynamic> json) {
    BenchmarkExercise? exercise;
    final exercisesData = json['exercises'];
    final exerciseData = json['exercise'];

    if (exercisesData != null && exercisesData is Map<String, dynamic>) {
      exercise = BenchmarkExercise.fromJson(exercisesData);
    } else if (exerciseData != null && exerciseData is Map<String, dynamic>) {
      exercise = BenchmarkExercise.fromJson(exerciseData);
    }

    return ExerciseBenchmark(
      id: json['id']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      exerciseId: json['exercise_id']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: BenchmarkUnit.fromString(json['unit']?.toString() ?? 'kg'),
      reps: json['reps'] as int?,
      sets: json['sets'] as int?,
      rpe: json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
      achievedAt: DateTime.tryParse(json['achieved_at']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes']?.toString(),
      isPr: json['is_pr'] as bool? ?? false,
      recordedById: json['recorded_by_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      exercise: exercise,
    );
  }

  /// Format value with unit for display
  String get formattedValue {
    if (unit == BenchmarkUnit.seconds && value >= 60) {
      final mins = (value / 60).floor();
      final secs = (value % 60).round();
      return '${mins}:${secs.toString().padLeft(2, '0')} min';
    }
    if (unit == BenchmarkUnit.minutes && value >= 60) {
      final hours = (value / 60).floor();
      final mins = (value % 60).round();
      return '${hours}h ${mins}m';
    }
    // Format decimal places based on unit
    final formatted = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    return '$formatted ${unit.displayLabel}';
  }

  /// Format reps for display (e.g., "5RM")
  String? get formattedReps => reps != null ? '${reps}RM' : null;
}

/// Exercise info for benchmark
class BenchmarkExercise {
  const BenchmarkExercise({
    required this.id,
    required this.name,
    this.nameEs,
    this.category,
    this.muscleGroups,
    this.gifUrl,
  });

  final String id;
  final String name;
  final String? nameEs;
  final String? category;
  final List<String>? muscleGroups;
  final String? gifUrl;

  factory BenchmarkExercise.fromJson(Map<String, dynamic> json) {
    return BenchmarkExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ejercicio',
      nameEs: json['name_es']?.toString(),
      category: json['category']?.toString(),
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      gifUrl: json['gif_url']?.toString(),
    );
  }

  /// Get localized name (prefer Spanish)
  String get displayName => nameEs ?? name;
}

/// Current PR summary (best per exercise)
class CurrentPR {
  const CurrentPR({
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseCategory,
    required this.value,
    required this.unit,
    this.reps,
    required this.achievedAt,
    required this.benchmarkId,
    this.gifUrl,
  });

  final String exerciseId;
  final String exerciseName;
  final String? exerciseCategory;
  final double value;
  final BenchmarkUnit unit;
  final int? reps;
  final DateTime achievedAt;
  final String benchmarkId;
  final String? gifUrl;

  factory CurrentPR.fromBenchmark(ExerciseBenchmark benchmark) {
    return CurrentPR(
      exerciseId: benchmark.exerciseId,
      exerciseName: benchmark.exercise?.displayName ?? 'Ejercicio',
      exerciseCategory: benchmark.exercise?.category,
      value: benchmark.value,
      unit: benchmark.unit,
      reps: benchmark.reps,
      achievedAt: benchmark.achievedAt,
      benchmarkId: benchmark.id,
      gifUrl: benchmark.exercise?.gifUrl,
    );
  }

  /// Format value with unit for display
  String get formattedValue {
    if (unit == BenchmarkUnit.seconds && value >= 60) {
      final mins = (value / 60).floor();
      final secs = (value % 60).round();
      return '${mins}:${secs.toString().padLeft(2, '0')} min';
    }
    final formatted = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    return '$formatted ${unit.displayLabel}';
  }

  /// Format reps for display
  String? get formattedReps => reps != null ? '${reps}RM' : null;
}

/// Chart data point for progress visualization
class BenchmarkChartPoint {
  const BenchmarkChartPoint({
    required this.date,
    required this.value,
    required this.isPr,
  });

  final DateTime date;
  final double value;
  final bool isPr;

  factory BenchmarkChartPoint.fromJson(Map<String, dynamic> json) {
    return BenchmarkChartPoint(
      date: DateTime.tryParse(json['achieved_at']?.toString() ?? '') ?? DateTime.now(),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      isPr: json['is_pr'] as bool? ?? false,
    );
  }
}

/// Benchmark form data for creating/updating
class BenchmarkFormData {
  const BenchmarkFormData({
    required this.exerciseId,
    required this.value,
    required this.unit,
    this.reps,
    this.sets,
    this.rpe,
    required this.achievedAt,
    this.notes,
  });

  final String exerciseId;
  final double value;
  final BenchmarkUnit unit;
  final int? reps;
  final int? sets;
  final double? rpe;
  final DateTime achievedAt;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'exercise_id': exerciseId,
        'value': value,
        'unit': unit.value,
        if (reps != null) 'reps': reps,
        if (sets != null) 'sets': sets,
        if (rpe != null) 'rpe': rpe,
        'achieved_at': achievedAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      };
}

/// Exercise option for dropdown/picker
class ExerciseOption {
  const ExerciseOption({
    required this.id,
    required this.name,
    this.nameEs,
    this.category,
  });

  final String id;
  final String name;
  final String? nameEs;
  final String? category;

  factory ExerciseOption.fromJson(Map<String, dynamic> json) {
    return ExerciseOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ejercicio',
      nameEs: json['name_es']?.toString(),
      category: json['category']?.toString(),
    );
  }

  String get displayName => nameEs ?? name;
}

/// Benchmark category for menu grid
class BenchmarkCategory {
  const BenchmarkCategory({
    required this.id,
    required this.title,
    this.subtitle,
    required this.iconAsset,
    required this.route,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String iconAsset;
  final String route;

  /// Predefined categories
  static const List<BenchmarkCategory> categories = [
    BenchmarkCategory(
      id: 'prs',
      title: 'PESOS / PRs',
      subtitle: 'Registra tus records personales',
      iconAsset: 'assets/icons/weight.svg',
      route: '/benchmarks/prs',
    ),
    // Future categories can be added here:
    // BenchmarkCategory(
    //   id: 'cardio',
    //   title: 'CARDIO',
    //   subtitle: 'Tiempos y distancias',
    //   iconAsset: 'assets/icons/cardio.svg',
    //   route: '/benchmarks/cardio',
    // ),
  ];
}
