/// Class generation models for bulk creating classes from templates
/// Matches the web implementation in web/src/actions/template.actions.ts

import 'class_template.dart';

/// Generation period options matching web
enum GenerationPeriod {
  week,
  twoWeeks,
  month;

  /// Get the number of days for this period
  int get days {
    switch (this) {
      case GenerationPeriod.week:
        return 7;
      case GenerationPeriod.twoWeeks:
        return 14;
      case GenerationPeriod.month:
        return 30;
    }
  }

  /// Get the display label
  String get label {
    switch (this) {
      case GenerationPeriod.week:
        return 'Próximos 7 días';
      case GenerationPeriod.twoWeeks:
        return 'Próximos 14 días';
      case GenerationPeriod.month:
        return 'Próximos 30 días';
    }
  }

  /// Get the web API value
  String get apiValue {
    switch (this) {
      case GenerationPeriod.week:
        return 'week';
      case GenerationPeriod.twoWeeks:
        return 'two_weeks';
      case GenerationPeriod.month:
        return 'month';
    }
  }
}

/// Preview data for a single template
class TemplateGenerationPreview {
  const TemplateGenerationPreview({
    required this.template,
    required this.dates,
    required this.alreadyGenerated,
    required this.toGenerate,
  });

  final ClassTemplate template;
  final List<DateTime> dates;
  final List<DateTime> alreadyGenerated;
  final List<DateTime> toGenerate;

  /// Number of new classes to generate
  int get newClassesCount => toGenerate.length;

  /// Number of existing classes (will be skipped)
  int get skippedCount => alreadyGenerated.length;

  factory TemplateGenerationPreview.fromJson(
    Map<String, dynamic> json,
    ClassTemplate template,
  ) {
    return TemplateGenerationPreview(
      template: template,
      dates: (json['dates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      alreadyGenerated: (json['alreadyGenerated'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      toGenerate: (json['toGenerate'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }
}

/// Full preview result for generation
class GenerationPreview {
  const GenerationPreview({
    required this.templatePreviews,
    required this.totalToGenerate,
    this.error,
  });

  final List<TemplateGenerationPreview> templatePreviews;
  final int totalToGenerate;
  final String? error;

  /// Total already generated (skipped)
  int get totalSkipped =>
      templatePreviews.fold(0, (sum, p) => sum + p.skippedCount);

  /// Number of active templates
  int get templateCount => templatePreviews.length;

  /// Check if there's anything to generate
  bool get hasClassesToGenerate => totalToGenerate > 0;

  factory GenerationPreview.empty() {
    return const GenerationPreview(
      templatePreviews: [],
      totalToGenerate: 0,
    );
  }

  factory GenerationPreview.error(String message) {
    return GenerationPreview(
      templatePreviews: const [],
      totalToGenerate: 0,
      error: message,
    );
  }
}

/// Result of class generation
class GenerationResult {
  const GenerationResult({
    required this.success,
    required this.message,
    required this.classesCreated,
    this.errors = const [],
  });

  final bool success;
  final String message;
  final int classesCreated;
  final List<String> errors;

  /// Has any non-fatal errors
  bool get hasErrors => errors.isNotEmpty;

  factory GenerationResult.success(int count) {
    return GenerationResult(
      success: true,
      message: count == 1
          ? 'Se generó 1 clase exitosamente'
          : 'Se generaron $count clases exitosamente',
      classesCreated: count,
    );
  }

  factory GenerationResult.successWithErrors(int count, List<String> errors) {
    return GenerationResult(
      success: true,
      message: count == 1
          ? 'Se generó 1 clase con algunos errores'
          : 'Se generaron $count clases con algunos errores',
      classesCreated: count,
      errors: errors,
    );
  }

  factory GenerationResult.error(String message) {
    return GenerationResult(
      success: false,
      message: message,
      classesCreated: 0,
    );
  }

  factory GenerationResult.fromJson(Map<String, dynamic> json) {
    return GenerationResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      classesCreated: json['classesCreated'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Generation log entry (for tracking what's been generated)
class ClassGenerationLog {
  const ClassGenerationLog({
    required this.id,
    required this.organizationId,
    required this.templateId,
    required this.generatedClassId,
    required this.generatedDate,
    this.createdAt,
  });

  final String id;
  final String organizationId;
  final String templateId;
  final String generatedClassId;
  final String generatedDate; // YYYY-MM-DD format
  final DateTime? createdAt;

  factory ClassGenerationLog.fromJson(Map<String, dynamic> json) {
    return ClassGenerationLog(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      templateId: json['template_id'] as String,
      generatedClassId: json['generated_class_id'] as String,
      generatedDate: json['generated_date'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'template_id': templateId,
      'generated_class_id': generatedClassId,
      'generated_date': generatedDate,
    };
  }
}

/// Helper class for date calculations matching web logic
class GenerationDateHelper {
  /// Get all dates for a specific day of week within a date range
  /// dayOfWeek: 0=Sunday, 1=Monday, ..., 6=Saturday
  static List<DateTime> getDatesForDayOfWeek(
    int dayOfWeek,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dates = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);

    // Find first occurrence of dayOfWeek
    // Dart weekday: 1=Monday, 7=Sunday
    // Web dayOfWeek: 0=Sunday, 1=Monday, ..., 6=Saturday
    // Convert: webDay 0 (Sunday) -> dartWeekday 7
    //          webDay 1 (Monday) -> dartWeekday 1
    final dartWeekday = dayOfWeek == 0 ? 7 : dayOfWeek;

    while (current.weekday != dartWeekday) {
      current = current.add(const Duration(days: 1));
    }

    // Collect all occurrences within range
    final endNormalized = DateTime(endDate.year, endDate.month, endDate.day);
    while (!current.isAfter(endNormalized)) {
      dates.add(current);
      current = current.add(const Duration(days: 7));
    }

    return dates;
  }

  /// Combine a date with a time string (HH:MM) to create a DateTime
  static DateTime combineDateTime(DateTime date, String timeStr) {
    final parts = timeStr.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hours, minutes);
  }

  /// Format a date as YYYY-MM-DD for the generation log
  static String formatDateForLog(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate end date based on start date and period
  static DateTime calculateEndDate(DateTime startDate, GenerationPeriod period) {
    return startDate.add(Duration(days: period.days));
  }
}
