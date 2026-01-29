import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/member.dart';

/// Result wrapper for paginated members
class MembersResult {
  const MembersResult({
    required this.members,
    required this.totalCount,
  });

  final List<Member> members;
  final int totalCount;
}

/// Result of member limit check
class MemberLimitResult {
  const MemberLimitResult({
    required this.allowed,
    required this.current,
    required this.limit,
    this.message,
  });

  final bool allowed;
  final int current;
  final int limit;
  final String? message;
}

/// Data for creating a new member
class CreateMemberData {
  const CreateMemberData({
    required this.email,
    required this.fullName,
    required this.locationId,
    this.phone,
    this.currentPlanId,
    this.membershipStartDate,
    this.membershipEndDate,
    this.experienceLevel = ExperienceLevel.beginner,
    this.status = MemberStatus.active,
  });

  final String email;
  final String fullName;
  final String locationId;
  final String? phone;
  final String? currentPlanId;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;
  final ExperienceLevel experienceLevel;
  final MemberStatus status;

  Map<String, dynamic> toJson(String organizationId) {
    return {
      'organization_id': organizationId,
      'location_id': locationId,
      'email': email.trim().toLowerCase(),
      'full_name': fullName.trim(),
      'phone': phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      'current_plan_id': currentPlanId,
      'membership_start_date': membershipStartDate?.toIso8601String().split('T')[0],
      'membership_end_date': membershipEndDate?.toIso8601String().split('T')[0],
      'experience_level': experienceLevel.name,
      'status': status.name,
    };
  }
}

/// Exception for member creation errors
class CreateMemberException implements Exception {
  const CreateMemberException(this.message, {this.code});

  final String message;
  final String? code;

  /// Check if this is a duplicate email error
  bool get isDuplicateEmail => code == '23505';

  /// Check if this is a plan limit exceeded error
  bool get isPlanLimitExceeded => code == 'PLAN_LIMIT_EXCEEDED';

  @override
  String toString() => message;
}

/// Repository for member operations with Supabase
/// Uses the members table with organization_id filter (RLS also enforces this)
class MembersRepository {
  MembersRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Get the organization ID for the current user
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

  /// Get paginated list of members for the organization
  /// Matches web contract: getMembers action
  ///
  /// If [locationId] is provided, filters members by location
  Future<MembersResult> getMembers({
    String? query,
    MemberStatus? status,
    ExperienceLevel? experienceLevel,
    String? locationId,
    int page = 1,
    int perPage = 20,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      debugPrint('MembersRepository.getMembers: No organization ID found');
      throw Exception('No hay sesion activa o no perteneces a una organizacion');
    }

    debugPrint('MembersRepository.getMembers: orgId=$organizationId, locationId=$locationId, page=$page, perPage=$perPage');

    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    // Build query
    var dbQuery = _supabase
        .from('members')
        .select()
        .eq('organization_id', organizationId);

    // Apply location filter if provided
    if (locationId != null) {
      dbQuery = dbQuery.eq('location_id', locationId);
    }

    // Apply search filter (name or email)
    if (query != null && query.isNotEmpty) {
      dbQuery = dbQuery.or('full_name.ilike.%$query%,email.ilike.%$query%');
    }

    // Apply status filter
    if (status != null) {
      dbQuery = dbQuery.eq('status', status.name);
    }

    // Apply experience level filter
    if (experienceLevel != null) {
      dbQuery = dbQuery.eq('experience_level', experienceLevel.name);
    }

    // Apply ordering and pagination
    final response = await dbQuery
        .order(sortBy, ascending: ascending)
        .range(from, to);

    debugPrint('MembersRepository.getMembers: Found ${response.length} members');

    final members = (response as List<dynamic>)
        .map((json) => Member.fromJson(json as Map<String, dynamic>))
        .toList();

    return MembersResult(
      members: members,
      totalCount: members.length,
    );
  }

  /// Get a single member by ID
  Future<Member?> getMember(String id) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No hay sesion activa o no perteneces a una organizacion');
    }

    final response = await _supabase
        .from('members')
        .select()
        .eq('id', id)
        .eq('organization_id', organizationId)
        .maybeSingle();

    if (response == null) return null;

    return Member.fromJson(response);
  }

  /// Search members by name or email
  ///
  /// If [locationId] is provided, filters members by location
  Future<List<Member>> searchMembers(
    String query, {
    String? locationId,
    int limit = 10,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return [];
    }

    if (query.isEmpty) {
      return [];
    }

    var dbQuery = _supabase
        .from('members')
        .select()
        .eq('organization_id', organizationId);

    // Apply location filter if provided
    if (locationId != null) {
      dbQuery = dbQuery.eq('location_id', locationId);
    }

    final response = await dbQuery
        .or('full_name.ilike.%$query%,email.ilike.%$query%')
        .limit(limit)
        .order('full_name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Member.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get members count by status
  ///
  /// If [locationId] is provided, filters counts by location
  Future<Map<MemberStatus, int>> getMemberCountsByStatus({
    String? locationId,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return {};
    }

    final counts = <MemberStatus, int>{};

    for (final status in MemberStatus.values) {
      var dbQuery = _supabase
          .from('members')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', status.name);

      if (locationId != null) {
        dbQuery = dbQuery.eq('location_id', locationId);
      }

      final response = await dbQuery;
      counts[status] = (response as List).length;
    }

    return counts;
  }

  /// Get total members count
  ///
  /// If [locationId] is provided, filters count by location
  Future<int> getTotalMembersCount({String? locationId}) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return 0;
    }

    var dbQuery = _supabase
        .from('members')
        .select('id')
        .eq('organization_id', organizationId);

    if (locationId != null) {
      dbQuery = dbQuery.eq('location_id', locationId);
    }

    final response = await dbQuery;
    return (response as List).length;
  }

  /// Check if organization can add more members (plan limit check)
  /// Matches web behavior: lib/plan-limits.ts → checkMemberLimit
  Future<MemberLimitResult> checkMemberLimit() async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return const MemberLimitResult(
        allowed: false,
        current: 0,
        limit: 0,
        message: 'No hay sesión activa',
      );
    }

    try {
      // Get organization limits
      final orgResponse = await _supabase
          .from('organizations')
          .select('max_members')
          .eq('id', organizationId)
          .maybeSingle();

      if (orgResponse == null) {
        return const MemberLimitResult(
          allowed: false,
          current: 0,
          limit: 0,
          message: 'Organización no encontrada',
        );
      }

      final maxMembers = orgResponse['max_members'] as int? ?? -1;

      // Unlimited check
      if (maxMembers == -1 || maxMembers >= 999999) {
        return const MemberLimitResult(allowed: true, current: 0, limit: -1);
      }

      // Count current members
      final countResponse = await _supabase
          .from('members')
          .select('id')
          .eq('organization_id', organizationId);

      final currentCount = (countResponse as List).length;

      if (currentCount >= maxMembers) {
        return MemberLimitResult(
          allowed: false,
          current: currentCount,
          limit: maxMembers,
          message: 'Has alcanzado el límite de $maxMembers miembros de tu plan. Actualiza tu plan para agregar más.',
        );
      }

      return MemberLimitResult(
        allowed: true,
        current: currentCount,
        limit: maxMembers,
      );
    } catch (e) {
      debugPrint('MembersRepository.checkMemberLimit: Error $e');
      return const MemberLimitResult(
        allowed: false,
        current: 0,
        limit: 0,
        message: 'Error al verificar límites',
      );
    }
  }

  /// Create a new member
  /// Matches web behavior: actions/member.actions.ts → createMemberData
  ///
  /// Throws [CreateMemberException] on error:
  /// - isDuplicateEmail: email already exists in organization
  /// - isPlanLimitExceeded: member limit reached
  Future<Member> createMember(CreateMemberData data) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw const CreateMemberException(
        'No hay sesión activa o no perteneces a una organización',
      );
    }

    debugPrint('MembersRepository.createMember: Creating member for org $organizationId');

    // Check member limit first
    final limitCheck = await checkMemberLimit();
    if (!limitCheck.allowed) {
      throw CreateMemberException(
        limitCheck.message ?? 'Límite de miembros alcanzado',
        code: 'PLAN_LIMIT_EXCEEDED',
      );
    }

    try {
      final insertData = data.toJson(organizationId);
      debugPrint('MembersRepository.createMember: Insert data: $insertData');

      final response = await _supabase
          .from('members')
          .insert(insertData)
          .select()
          .single();

      debugPrint('MembersRepository.createMember: Member created successfully');
      return Member.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('MembersRepository.createMember: PostgrestException ${e.code}: ${e.message}');

      // Handle duplicate email error
      if (e.code == '23505') {
        throw const CreateMemberException(
          'Ya existe un miembro con este email',
          code: '23505',
        );
      }

      // Handle RLS violation
      if (e.code == '42501' || e.message.contains('policy')) {
        throw const CreateMemberException(
          'No tienes permisos para crear miembros',
          code: '42501',
        );
      }

      throw CreateMemberException(e.message, code: e.code);
    } catch (e) {
      debugPrint('MembersRepository.createMember: Error $e');
      throw CreateMemberException('Error al crear miembro: $e');
    }
  }
}
