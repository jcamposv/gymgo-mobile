import 'package:equatable/equatable.dart';
import 'routine.dart';

/// Weekly progress for a training program
class WeeklyProgress extends Equatable {
  const WeeklyProgress({
    required this.currentWeek,
    required this.totalWeeks,
    required this.daysCompletedThisWeek,
    required this.daysPerWeek,
    required this.weekPercentage,
  });

  final int currentWeek;
  final int totalWeeks;
  final int daysCompletedThisWeek;
  final int daysPerWeek;
  final int weekPercentage;

  /// Check if current week is complete
  bool get isWeekComplete => daysCompletedThisWeek >= daysPerWeek;

  /// Days remaining this week
  int get daysRemainingThisWeek => daysPerWeek - daysCompletedThisWeek;

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyProgress(
      currentWeek: json['currentWeek'] as int? ?? 1,
      totalWeeks: json['totalWeeks'] as int? ?? 12,
      daysCompletedThisWeek: json['daysCompletedThisWeek'] as int? ?? 0,
      daysPerWeek: json['daysPerWeek'] as int? ?? 3,
      weekPercentage: json['weekPercentage'] as int? ?? 0,
    );
  }

  /// Create from raw completion data
  factory WeeklyProgress.calculate({
    required int totalCompletions,
    required int daysPerWeek,
    required int durationWeeks,
  }) {
    final currentWeek = (totalCompletions ~/ daysPerWeek) + 1;
    final daysThisWeek = totalCompletions % daysPerWeek;
    final weekPercentage = ((daysThisWeek / daysPerWeek) * 100).round();

    return WeeklyProgress(
      currentWeek: currentWeek,
      totalWeeks: durationWeeks,
      daysCompletedThisWeek: daysThisWeek,
      daysPerWeek: daysPerWeek,
      weekPercentage: weekPercentage,
    );
  }

  @override
  List<Object?> get props => [
        currentWeek,
        totalWeeks,
        daysCompletedThisWeek,
        daysPerWeek,
        weekPercentage,
      ];
}

/// Overall program progress
class ProgramProgress extends Equatable {
  const ProgramProgress({
    required this.totalDaysCompleted,
    required this.totalDaysInProgram,
    required this.currentWeek,
    required this.totalWeeks,
    required this.percentageComplete,
    required this.daysRemaining,
    required this.isCompleted,
  });

  final int totalDaysCompleted;
  final int totalDaysInProgram;
  final int currentWeek;
  final int totalWeeks;
  final int percentageComplete;
  final int daysRemaining;
  final bool isCompleted;

  factory ProgramProgress.fromJson(Map<String, dynamic> json) {
    return ProgramProgress(
      totalDaysCompleted: json['totalDaysCompleted'] as int? ?? 0,
      totalDaysInProgram: json['totalDaysInProgram'] as int? ?? 0,
      currentWeek: json['currentWeek'] as int? ?? 1,
      totalWeeks: json['totalWeeks'] as int? ?? 12,
      percentageComplete: json['percentageComplete'] as int? ?? 0,
      daysRemaining: json['daysRemaining'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// Create from raw data
  factory ProgramProgress.calculate({
    required int totalCompletions,
    required int daysPerWeek,
    required int durationWeeks,
  }) {
    final totalDaysInProgram = daysPerWeek * durationWeeks;
    final currentWeek = (totalCompletions ~/ daysPerWeek) + 1;
    final percentageComplete =
        ((totalCompletions / totalDaysInProgram) * 100).round();
    final daysRemaining = totalDaysInProgram - totalCompletions;
    final isCompleted = totalCompletions >= totalDaysInProgram;

    return ProgramProgress(
      totalDaysCompleted: totalCompletions,
      totalDaysInProgram: totalDaysInProgram,
      currentWeek: currentWeek,
      totalWeeks: durationWeeks,
      percentageComplete: percentageComplete.clamp(0, 100),
      daysRemaining: daysRemaining.clamp(0, totalDaysInProgram),
      isCompleted: isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        totalDaysCompleted,
        totalDaysInProgram,
        currentWeek,
        totalWeeks,
        percentageComplete,
        isCompleted,
      ];
}

/// Today's workout information
class TodaysWorkout extends Equatable {
  const TodaysWorkout({
    required this.workout,
    required this.progress,
    required this.program,
    required this.nextDayNumber,
    required this.hasActiveProgram,
    this.exerciseDetails,
    this.isCompletedToday = false,
  });

  final Routine? workout;           // The workout for today (null if program complete)
  final WeeklyProgress progress;    // Weekly progress info
  final ProgramInfo program;        // Program basic info
  final int nextDayNumber;          // Which day number is next (1-6)
  final bool hasActiveProgram;      // Whether member has an active program
  final Map<String, dynamic>? exerciseDetails; // Full exercise details
  final bool isCompletedToday;      // Whether today's workout is already done

  /// Check if program is complete
  bool get isProgramComplete =>
      progress.currentWeek > progress.totalWeeks ||
      (workout == null && hasActiveProgram);

  factory TodaysWorkout.empty() {
    return TodaysWorkout(
      workout: null,
      progress: const WeeklyProgress(
        currentWeek: 1,
        totalWeeks: 1,
        daysCompletedThisWeek: 0,
        daysPerWeek: 1,
        weekPercentage: 0,
      ),
      program: const ProgramInfo(id: '', name: '', totalWeeks: 0),
      nextDayNumber: 1,
      hasActiveProgram: false,
    );
  }

  @override
  List<Object?> get props => [
        workout?.id,
        progress,
        program,
        nextDayNumber,
        hasActiveProgram,
        isCompletedToday,
      ];
}

/// Basic program info
class ProgramInfo extends Equatable {
  const ProgramInfo({
    required this.id,
    required this.name,
    required this.totalWeeks,
    this.daysPerWeek,
    this.description,
  });

  final String id;
  final String name;
  final int totalWeeks;
  final int? daysPerWeek;
  final String? description;

  factory ProgramInfo.fromJson(Map<String, dynamic> json) {
    return ProgramInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      totalWeeks: json['totalWeeks'] as int? ?? json['duration_weeks'] as int? ?? 12,
      daysPerWeek: json['daysPerWeek'] as int? ?? json['days_per_week'] as int?,
      description: json['description'] as String?,
    );
  }

  factory ProgramInfo.fromRoutine(Routine routine) {
    return ProgramInfo(
      id: routine.id,
      name: routine.name,
      totalWeeks: routine.durationWeeks ?? 12,
      daysPerWeek: routine.daysPerWeek,
      description: routine.description,
    );
  }

  @override
  List<Object?> get props => [id, name, totalWeeks, daysPerWeek];
}

/// Workout completion record
class WorkoutCompletion extends Equatable {
  const WorkoutCompletion({
    required this.id,
    required this.organizationId,
    required this.workoutId,
    required this.memberId,
    required this.completedAt,
    required this.completedDate,
    this.programWeek,
    this.durationMinutes,
    this.notes,
  });

  final String id;
  final String organizationId;
  final String workoutId;
  final String memberId;
  final DateTime completedAt;
  final DateTime completedDate;
  final int? programWeek;
  final int? durationMinutes;
  final String? notes;

  factory WorkoutCompletion.fromJson(Map<String, dynamic> json) {
    return WorkoutCompletion(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      workoutId: json['workout_id'] as String,
      memberId: json['member_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      completedDate: DateTime.parse(json['completed_date'] as String),
      programWeek: json['program_week'] as int?,
      durationMinutes: json['duration_minutes'] as int?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, workoutId, memberId, completedDate];
}

/// Program day with completion status
class ProgramDay extends Equatable {
  const ProgramDay({
    required this.workout,
    required this.dayNumber,
    required this.isCompleted,
    required this.isNext,
    this.completedAt,
  });

  final Routine workout;
  final int dayNumber;
  final bool isCompleted;
  final bool isNext;
  final DateTime? completedAt;

  /// Day display name (e.g., "Día 1" or custom name)
  String get displayName {
    if (workout.name.isNotEmpty &&
        !workout.name.toLowerCase().startsWith('día') &&
        !workout.name.toLowerCase().startsWith('day')) {
      return workout.name;
    }
    return 'Día $dayNumber';
  }

  @override
  List<Object?> get props => [workout.id, dayNumber, isCompleted, isNext];
}
