import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/class_generation.dart';
import '../domain/class_template.dart';

/// Repository for bulk class generation from templates
/// Implements the same logic as web/src/actions/template.actions.ts
class ClassGenerationRepository {
  ClassGenerationRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Get the current user's organization ID
  Future<String?> _getOrganizationId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('organization_id')
        .eq('id', userId)
        .maybeSingle();

    return response?['organization_id'] as String?;
  }

  /// Preview class generation without actually creating classes
  /// Returns a preview of what would be generated
  Future<GenerationPreview> previewGeneration({
    required GenerationPeriod period,
    DateTime? startDate,
    List<String>? templateIds,
  }) async {
    try {
      final orgId = await _getOrganizationId();
      if (orgId == null) {
        return GenerationPreview.error('Usuario no autenticado');
      }

      // Calculate date range
      final start = startDate ?? DateTime.now();
      final startNormalized = DateTime(start.year, start.month, start.day);
      final end = GenerationDateHelper.calculateEndDate(startNormalized, period);

      // Fetch active templates
      var query = _supabase
          .from('class_templates')
          .select()
          .eq('organization_id', orgId)
          .eq('is_active', true);

      if (templateIds != null && templateIds.isNotEmpty) {
        query = query.inFilter('id', templateIds);
      }

      final templatesResponse = await query.order('day_of_week');
      final templates = (templatesResponse as List<dynamic>)
          .map((json) => ClassTemplate.fromJson(json as Map<String, dynamic>))
          .toList();

      if (templates.isEmpty) {
        return GenerationPreview.error('No hay plantillas activas');
      }

      // Build preview for each template
      final previews = <TemplateGenerationPreview>[];
      var totalToGenerate = 0;

      for (final template in templates) {
        // Get all dates for this template's day of week
        final dates = GenerationDateHelper.getDatesForDayOfWeek(
          template.dayOfWeek,
          startNormalized,
          end,
        );

        if (dates.isEmpty) continue;

        // Check which dates are already generated
        final dateStrings =
            dates.map(GenerationDateHelper.formatDateForLog).toList();

        final existingLogs = await _supabase
            .from('class_generation_log')
            .select('generated_date')
            .eq('template_id', template.id)
            .inFilter('generated_date', dateStrings);

        final existingDateStrings = (existingLogs as List<dynamic>)
            .map((log) => log['generated_date'] as String)
            .toSet();

        final alreadyGenerated = <DateTime>[];
        final toGenerate = <DateTime>[];

        for (final date in dates) {
          final dateStr = GenerationDateHelper.formatDateForLog(date);
          if (existingDateStrings.contains(dateStr)) {
            alreadyGenerated.add(date);
          } else {
            toGenerate.add(date);
          }
        }

        previews.add(TemplateGenerationPreview(
          template: template,
          dates: dates,
          alreadyGenerated: alreadyGenerated,
          toGenerate: toGenerate,
        ));

        totalToGenerate += toGenerate.length;
      }

      return GenerationPreview(
        templatePreviews: previews,
        totalToGenerate: totalToGenerate,
      );
    } catch (e) {
      return GenerationPreview.error('Error al previsualizar: $e');
    }
  }

  /// Generate classes from templates for the specified period
  /// Uses class_generation_log for deduplication (same as web)
  Future<GenerationResult> generateClasses({
    required GenerationPeriod period,
    DateTime? startDate,
    List<String>? templateIds,
  }) async {
    try {
      final orgId = await _getOrganizationId();
      if (orgId == null) {
        return GenerationResult.error('Usuario no autenticado');
      }

      // Calculate date range
      final start = startDate ?? DateTime.now();
      final startNormalized = DateTime(start.year, start.month, start.day);
      final end = GenerationDateHelper.calculateEndDate(startNormalized, period);

      // Fetch active templates
      var query = _supabase
          .from('class_templates')
          .select()
          .eq('organization_id', orgId)
          .eq('is_active', true);

      if (templateIds != null && templateIds.isNotEmpty) {
        query = query.inFilter('id', templateIds);
      }

      final templatesResponse = await query.order('day_of_week');
      final templates = (templatesResponse as List<dynamic>)
          .map((json) => ClassTemplate.fromJson(json as Map<String, dynamic>))
          .toList();

      if (templates.isEmpty) {
        return GenerationResult.error('No hay plantillas activas');
      }

      var classesCreated = 0;
      final errors = <String>[];

      // Process each template
      for (final template in templates) {
        // Get all dates for this template's day of week
        final dates = GenerationDateHelper.getDatesForDayOfWeek(
          template.dayOfWeek,
          startNormalized,
          end,
        );

        // Process each date
        for (final date in dates) {
          final dateStr = GenerationDateHelper.formatDateForLog(date);

          // Check if already generated (deduplication)
          final existingLog = await _supabase
              .from('class_generation_log')
              .select('id')
              .eq('template_id', template.id)
              .eq('generated_date', dateStr)
              .maybeSingle();

          if (existingLog != null) {
            // Already generated, skip
            continue;
          }

          // Calculate start and end times
          final classStartTime =
              GenerationDateHelper.combineDateTime(date, template.startTime);
          final classEndTime =
              GenerationDateHelper.combineDateTime(date, template.endTime);

          // Create the class
          try {
            final classData = {
              'organization_id': orgId,
              'name': template.name,
              'description': template.description,
              'class_type': template.classType,
              'start_time': classStartTime.toIso8601String(),
              'end_time': classEndTime.toIso8601String(),
              'max_capacity': template.maxCapacity,
              'waitlist_enabled': template.waitlistEnabled,
              'max_waitlist': template.maxWaitlist,
              'instructor_id': template.instructorId,
              'instructor_name': template.instructorName,
              'location': template.location,
              'booking_opens_hours': template.bookingOpensHours,
              'booking_closes_minutes': template.bookingClosesMinutes,
              'cancellation_deadline_hours': template.cancellationDeadlineHours,
              'is_cancelled': false,
            };

            final classResponse = await _supabase
                .from('classes')
                .insert(classData)
                .select('id')
                .single();

            final generatedClassId = classResponse['id'] as String;

            // Log the generation for deduplication
            try {
              await _supabase.from('class_generation_log').insert({
                'organization_id': orgId,
                'template_id': template.id,
                'generated_class_id': generatedClassId,
                'generated_date': dateStr,
              });
            } catch (logError) {
              // Log error is non-fatal, class was still created
              errors.add(
                'Error registrando generación para ${template.name} el $dateStr: $logError',
              );
            }

            classesCreated++;
          } catch (classError) {
            // Class creation error is non-fatal, continue with others
            errors.add(
              'Error creando clase para ${template.name} el $dateStr: $classError',
            );
          }
        }
      }

      // Return result
      if (classesCreated == 0 && errors.isEmpty) {
        return const GenerationResult(
          success: true,
          message: 'No hay clases nuevas para generar',
          classesCreated: 0,
        );
      }

      if (errors.isNotEmpty) {
        return GenerationResult.successWithErrors(classesCreated, errors);
      }

      return GenerationResult.success(classesCreated);
    } catch (e) {
      return GenerationResult.error('Error al generar clases: $e');
    }
  }

  /// Get generation history (for debugging/auditing)
  Future<List<ClassGenerationLog>> getGenerationHistory({
    int limit = 50,
  }) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) return [];

    final response = await _supabase
        .from('class_generation_log')
        .select()
        .eq('organization_id', orgId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((json) =>
            ClassGenerationLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
