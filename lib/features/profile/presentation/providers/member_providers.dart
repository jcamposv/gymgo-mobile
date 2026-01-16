import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/member.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for the current logged-in member
/// Fetches member data from the members table using the authenticated user's profile_id
final currentMemberProvider = FutureProvider<Member?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  debugPrint('currentMemberProvider: Looking up member for profile_id: ${user.id}');

  try {
    final supabase = Supabase.instance.client;

    // First try to find member by profile_id (the auth user UUID)
    var response = await supabase
        .from('members')
        .select()
        .eq('profile_id', user.id)
        .maybeSingle();

    // Fallback: try by email if not found by profile_id
    if (response == null && user.email != null) {
      debugPrint('currentMemberProvider: Not found by profile_id, trying email: ${user.email}');

      // Get user's organization from profile first
      final profileResponse = await supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', user.id)
          .maybeSingle();

      final organizationId = profileResponse?['organization_id'] as String?;

      if (organizationId != null) {
        response = await supabase
            .from('members')
            .select()
            .eq('email', user.email!)
            .eq('organization_id', organizationId)
            .maybeSingle();
      }
    }

    if (response != null) {
      debugPrint('currentMemberProvider: Found member with id: ${response['id']}');
      debugPrint('currentMemberProvider: organization_id: ${response['organization_id']}');
      return Member.fromJson(response);
    }

    debugPrint('currentMemberProvider: No member found, using user data as fallback');
    // Return a basic member from user data if not found in members table
    return Member(
      id: user.id,
      name: user.email?.split('@').first ?? 'Usuario',
      email: user.email,
    );
  } catch (e) {
    debugPrint('currentMemberProvider: Error loading member: $e');
    // Return a basic member from user data on error
    return Member(
      id: user.id,
      name: user.email?.split('@').first ?? 'Usuario',
      email: user.email,
    );
  }
});

/// Provider for member's organization ID
final memberOrganizationIdProvider = FutureProvider<String?>((ref) async {
  final member = await ref.watch(currentMemberProvider.future);
  return member?.organizationId;
});
