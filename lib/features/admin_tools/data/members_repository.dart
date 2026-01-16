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
  Future<MembersResult> getMembers({
    String? query,
    MemberStatus? status,
    ExperienceLevel? experienceLevel,
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

    debugPrint('MembersRepository.getMembers: orgId=$organizationId, page=$page, perPage=$perPage');

    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    // Build query
    var dbQuery = _supabase
        .from('members')
        .select()
        .eq('organization_id', organizationId);

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
  Future<List<Member>> searchMembers(String query, {int limit = 10}) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return [];
    }

    if (query.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('members')
        .select()
        .eq('organization_id', organizationId)
        .or('full_name.ilike.%$query%,email.ilike.%$query%')
        .limit(limit)
        .order('full_name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Member.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get members count by status
  Future<Map<MemberStatus, int>> getMemberCountsByStatus() async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return {};
    }

    final counts = <MemberStatus, int>{};

    for (final status in MemberStatus.values) {
      final response = await _supabase
          .from('members')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', status.name);

      counts[status] = (response as List).length;
    }

    return counts;
  }

  /// Get total members count
  Future<int> getTotalMembersCount() async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      return 0;
    }

    final response = await _supabase
        .from('members')
        .select('id')
        .eq('organization_id', organizationId);

    return (response as List).length;
  }
}
