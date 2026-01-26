import 'package:equatable/equatable.dart';

/// Workout type enum matching web model
enum WorkoutType {
  routine('routine', 'Rutina'),
  wod('wod', 'WOD'),
  program('program', 'Programa');

  const WorkoutType(this.value, this.label);
  final String value;
  final String label;

  static WorkoutType fromString(String? value) {
    return WorkoutType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkoutType.routine,
    );
  }
}

/// WOD type enum for specialized workouts
enum WodType {
  amrap('amrap', 'AMRAP', 'As Many Rounds As Possible'),
  emom('emom', 'EMOM', 'Every Minute On the Minute'),
  forTime('for_time', 'For Time', 'Complete as fast as possible'),
  tabata('tabata', 'Tabata', 'Tabata interval protocol'),
  rounds('rounds', 'Rounds', 'Rounds for Quality');

  const WodType(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  static WodType? fromString(String? value) {
    if (value == null) return null;
    return WodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WodType.amrap,
    );
  }
}

/// Exercise item within a routine
class ExerciseItem extends Equatable {
  const ExerciseItem({
    required this.exerciseId,
    required this.exerciseName,
    required this.order,
    this.sets,
    this.reps,
    this.weight,
    this.restSeconds,
    this.tempo,
    this.notes,
    // Exercise details (populated from exercises table)
    this.gifUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.category,
    this.difficulty,
    this.muscleGroups,
    this.instructions,
  });

  final String exerciseId;
  final String exerciseName;
  final int order;
  final int? sets;
  final String? reps;
  final String? weight;
  final int? restSeconds;
  final String? tempo;
  final String? notes;

  // Exercise details from exercises table
  final String? gifUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? category;
  final String? difficulty;
  final List<String>? muscleGroups;
  final String? instructions;

  /// Check if exercise has media
  bool get hasMedia => gifUrl != null || videoUrl != null;

  /// Get display string for sets/reps
  String get setsRepsDisplay {
    if (sets == null && reps == null) return '';
    if (sets != null && reps != null) return '$sets x $reps';
    if (sets != null) return '$sets sets';
    return reps ?? '';
  }

  /// Get rest time formatted
  String get restDisplay {
    if (restSeconds == null || restSeconds == 0) return '';
    if (restSeconds! >= 60) {
      final mins = restSeconds! ~/ 60;
      final secs = restSeconds! % 60;
      return secs > 0 ? '${mins}m ${secs}s' : '${mins}m';
    }
    return '${restSeconds}s';
  }

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      order: json['order'] as int? ?? 0,
      sets: json['sets'] as int?,
      reps: json['reps'] as String?,
      weight: json['weight'] as String?,
      restSeconds: json['rest_seconds'] as int?,
      tempo: json['tempo'] as String?,
      notes: json['notes'] as String?,
      gifUrl: json['gif_url'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'order': order,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (tempo != null) 'tempo': tempo,
      if (notes != null) 'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        exerciseId,
        exerciseName,
        order,
        sets,
        reps,
        weight,
        restSeconds,
        tempo,
        notes,
      ];
}

/// Main Routine entity (also used for program days)
class Routine extends Equatable {
  const Routine({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.workoutType,
    this.wodType,
    this.wodTimeCap,
    required this.exercises,
    this.assignedToMemberId,
    this.assignedById,
    this.scheduledDate,
    required this.isTemplate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    // Joined member data
    this.memberName,
    this.memberEmail,
    // Program fields (Migration 027)
    this.programId,
    this.dayNumber,
    this.durationWeeks,
    this.daysPerWeek,
    this.programStartDate,
  });

  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final WorkoutType workoutType;
  final WodType? wodType;
  final int? wodTimeCap;
  final List<ExerciseItem> exercises;
  final String? assignedToMemberId;
  final String? assignedById;
  final DateTime? scheduledDate;
  final bool isTemplate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined member data
  final String? memberName;
  final String? memberEmail;

  // Program fields (Migration 027)
  final String? programId;       // Parent program ID (null = this IS a program or standalone)
  final int? dayNumber;          // Day number in program (1-6)
  final int? durationWeeks;      // Program duration in weeks (4, 6, 8, 12)
  final int? daysPerWeek;        // Training days per week (2-6)
  final DateTime? programStartDate; // When member started program

  /// Check if this is a program parent (has days)
  bool get isProgram => programId == null && daysPerWeek != null;

  /// Check if this is a program day (child of a program)
  bool get isProgramDay => programId != null && dayNumber != null;

  /// Get exercise count
  int get exerciseCount => exercises.length;

  /// Check if routine is a WOD
  bool get isWod => workoutType == WorkoutType.wod;

  /// Get estimated duration in minutes (rough calculation)
  int get estimatedDuration {
    if (wodTimeCap != null) return wodTimeCap!;
    // Estimate: 3 min per exercise with sets, 1 min for simple exercises
    return exercises.fold(0, (sum, ex) {
      final exerciseTime = (ex.sets ?? 1) * 2 + (ex.restSeconds ?? 30) ~/ 60;
      return sum + exerciseTime.clamp(1, 10);
    });
  }

  /// Get workout type display with WOD details
  String get typeDisplay {
    if (workoutType == WorkoutType.wod && wodType != null) {
      final timeCap = wodTimeCap != null ? ' - ${wodTimeCap}min' : '';
      return '${wodType!.label}$timeCap';
    }
    return workoutType.label;
  }

  /// Check if assigned to a member
  bool get isAssigned => assignedToMemberId != null;

  factory Routine.fromJson(Map<String, dynamic> json) {
    // Parse exercises from JSON array
    List<ExerciseItem> exercisesList = [];
    final exercisesJson = json['exercises'];
    if (exercisesJson != null) {
      if (exercisesJson is List) {
        exercisesList = exercisesJson
            .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort by order
        exercisesList.sort((a, b) => a.order.compareTo(b.order));
      }
    }

    // Parse member data from join
    String? memberName;
    String? memberEmail;
    final memberData = json['member'];
    if (memberData != null && memberData is Map<String, dynamic>) {
      memberName = memberData['full_name'] as String? ??
                   memberData['name'] as String?;
      memberEmail = memberData['email'] as String?;
    }

    return Routine(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      workoutType: WorkoutType.fromString(json['workout_type'] as String?),
      wodType: WodType.fromString(json['wod_type'] as String?),
      wodTimeCap: json['wod_time_cap'] as int?,
      exercises: exercisesList,
      assignedToMemberId: json['assigned_to_member_id'] as String?,
      assignedById: json['assigned_by_id'] as String?,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      isTemplate: json['is_template'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberName: memberName,
      memberEmail: memberEmail,
      // Program fields (Migration 027)
      programId: json['program_id'] as String?,
      dayNumber: json['day_number'] as int?,
      durationWeeks: json['duration_weeks'] as int?,
      daysPerWeek: json['days_per_week'] as int?,
      programStartDate: json['program_start_date'] != null
          ? DateTime.parse(json['program_start_date'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        name,
        description,
        workoutType,
        wodType,
        wodTimeCap,
        exercises,
        assignedToMemberId,
        scheduledDate,
        isTemplate,
        isActive,
        createdAt,
        programId,
        dayNumber,
        daysPerWeek,
      ];
}

/// Exercise entity with full details (from exercises table)
class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.difficulty,
    this.muscleGroups,
    this.equipment,
    this.gifUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.instructions,
    this.tips,
  });

  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? difficulty;
  final List<String>? muscleGroups;
  final List<String>? equipment;
  final String? gifUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? instructions;
  final String? tips;

  bool get hasMedia => gifUrl != null || videoUrl != null;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Handle instructions - can be array or string
    String? instructions;
    final rawInstructions = json['instructions'];
    if (rawInstructions is List) {
      instructions = rawInstructions.cast<String>().join('\n');
    } else if (rawInstructions is String) {
      instructions = rawInstructions;
    }

    // Handle tips - can be array or string
    String? tips;
    final rawTips = json['tips'];
    if (rawTips is List) {
      tips = rawTips.cast<String>().join('\n');
    } else if (rawTips is String) {
      tips = rawTips;
    }

    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      equipment: (json['equipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gifUrl: json['gif_url'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      instructions: instructions,
      tips: tips,
    );
  }

  @override
  List<Object?> get props => [id, name, category, difficulty];
}
