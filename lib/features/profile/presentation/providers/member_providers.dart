import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/member.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for the current logged-in member
/// Fetches member data from the members table using the authenticated user's ID
final currentMemberProvider = FutureProvider<Member?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  debugPrint('currentMemberProvider: Looking up member for user_id: ${user.id}');

  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('members')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

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
