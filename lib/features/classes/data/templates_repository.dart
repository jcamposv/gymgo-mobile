import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/class_template.dart';

/// Repository for class template operations with Supabase
class TemplatesRepository {
  TemplatesRepository(this._supabase);

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

  /// Get all active templates
  Future<List<ClassTemplate>> getTemplates({
    String? searchQuery,
    int? dayOfWeek,
    String? classType,
    bool activeOnly = true,
  }) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    var query = _supabase.from('class_templates').select();

    // Filter by organization
    query = query.eq('organization_id', orgId);

    // Filter by active status
    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    // Filter by day of week
    if (dayOfWeek != null) {
      query = query.eq('day_of_week', dayOfWeek);
    }

    // Filter by class type
    if (classType != null && classType.isNotEmpty) {
      query = query.eq('class_type', classType);
    }

    // Search by name
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    // Order by day and time
    final response = await query
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    return (response as List<dynamic>)
        .map((json) => ClassTemplate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single template by ID
  Future<ClassTemplate?> getTemplateById(String templateId) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('class_templates')
        .select()
        .eq('id', templateId)
        .eq('organization_id', orgId)
        .maybeSingle();

    if (response == null) return null;
    return ClassTemplate.fromJson(response);
  }

  /// Update a template
  Future<ClassTemplate> updateTemplate(
    String templateId,
    UpdateTemplateDto dto,
  ) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('class_templates')
        .update(dto.toJson())
        .eq('id', templateId)
        .eq('organization_id', orgId)
        .select()
        .single();

    return ClassTemplate.fromJson(response);
  }

  /// Create a new template
  Future<ClassTemplate> createTemplate(CreateTemplateDto dto) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('class_templates')
        .insert(dto.toJson(orgId))
        .select()
        .single();

    return ClassTemplate.fromJson(response);
  }

  /// Delete a template (HARD DELETE - matches web implementation)
  Future<void> deleteTemplate(String templateId) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('class_templates')
        .delete()
        .eq('id', templateId)
        .eq('organization_id', orgId);
  }

  /// Toggle template active status (soft enable/disable)
  Future<ClassTemplate> toggleTemplateStatus(
    String templateId, {
    required bool isActive,
  }) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('class_templates')
        .update({'is_active': isActive})
        .eq('id', templateId)
        .eq('organization_id', orgId)
        .select()
        .single();

    return ClassTemplate.fromJson(response);
  }

  /// Deactivate a template (soft delete)
  Future<void> deactivateTemplate(String templateId) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('class_templates')
        .update({'is_active': false})
        .eq('id', templateId)
        .eq('organization_id', orgId);
  }

  /// Get instructors for picker
  Future<List<Instructor>> getInstructors({String? searchQuery}) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    var query = _supabase
        .from('profiles')
        .select('id, email, full_name, avatar_url, role')
        .eq('organization_id', orgId)
        .inFilter('role', ['admin', 'instructor', 'owner', 'super_admin', 'trainer', 'assistant']);

    // Search by name or email
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
    }

    final response = await query.order('full_name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Instructor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single instructor by ID
  Future<Instructor?> getInstructorById(String instructorId) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('profiles')
        .select('id, email, full_name, avatar_url, role')
        .eq('id', instructorId)
        .eq('organization_id', orgId)
        .maybeSingle();

    if (response == null) return null;
    return Instructor.fromJson(response);
  }

  /// Create a class from template
  Future<Map<String, dynamic>> createClass(CreateClassDto dto) async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('classes')
        .insert(dto.toJson(orgId))
        .select()
        .single();

    return response;
  }

  /// Get unique locations from existing templates
  Future<List<String>> getLocations() async {
    final orgId = await _getOrganizationId();
    if (orgId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('class_templates')
        .select('location')
        .eq('organization_id', orgId)
        .not('location', 'is', null);

    final locations = <String>{};
    for (final row in response as List<dynamic>) {
      final location = row['location'] as String?;
      if (location != null && location.isNotEmpty) {
        locations.add(location);
      }
    }

    return locations.toList()..sort();
  }
}
