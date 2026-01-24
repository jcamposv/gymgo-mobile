import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/rbac/rbac.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

/// User profile with role information
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.organizationId,
  });

  final String id;
  final String email;
  final AppRole role;
  final String? fullName;
  final String? avatarUrl;
  final String? organizationId;

  /// Check if user has a specific permission
  bool hasPermission(AppPermission permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Check if user can access Admin Tools
  bool get canAccessAdminTools => adminToolsRoles.contains(role);

  /// Check if user is admin
  bool get isAdmin => adminRoles.contains(role);

  /// Check if user is staff
  bool get isStaff => staffRoles.contains(role);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: AppRole.fromString(json['role'] as String?),
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      organizationId: json['organization_id'] as String?,
    );
  }
}

/// Provider for the current user's profile with role
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  debugPrint('userProfileProvider: Fetching profile for user_id: ${user.id}');

  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('profiles')
        .select('id, email, full_name, avatar_url, role, organization_id')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      final profile = UserProfile.fromJson(response);
      debugPrint('userProfileProvider: Found profile with role: ${profile.role.value}');
      return profile;
    }

    debugPrint('userProfileProvider: No profile found, using default client role');
    // Return default profile with client role
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      role: AppRole.client,
    );
  } catch (e) {
    debugPrint('userProfileProvider: Error loading profile: $e');
    // Return default profile on error
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      role: AppRole.client,
    );
  }
});

/// Provider for the current user's role
final userRoleProvider = Provider<AppRole>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.role ?? AppRole.client,
    orElse: () => AppRole.client,
  );
});

/// Provider to check if current user can access Admin Tools
final canAccessAdminToolsProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return canAccessAdminTools(role);
});

/// Provider to check if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return isAdmin(role);
});

/// Provider to check if current user is staff
final isStaffProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return isStaff(role);
});

/// Provider to check a specific permission for current user
final hasPermissionProvider = Provider.family<bool, AppPermission>((ref, permission) {
  final role = ref.watch(userRoleProvider);
  return hasPermission(role, permission);
});

/// Provider for the current user's organization ID
/// This is a centralized source for organization_id to avoid multiple queries
final currentOrganizationIdProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.organizationId,
    orElse: () => null,
  );
});

/// Async version that waits for the profile to load
final currentOrganizationIdAsyncProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.organizationId;
});
