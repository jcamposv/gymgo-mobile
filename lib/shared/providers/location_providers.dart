import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../data/location_repository.dart';
import '../domain/location.dart';
import 'role_providers.dart';

/// Repository provider for location data
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

/// Provider for all locations in the user's organization
final organizationLocationsProvider = FutureProvider<List<Location>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.read(locationRepositoryProvider);
  return repository.getLocations();
});

/// Provider for the primary location in the organization
final primaryLocationProvider = FutureProvider<Location?>((ref) async {
  final locations = await ref.watch(organizationLocationsProvider.future);
  return locations.firstWhere(
    (loc) => loc.isPrimary,
    orElse: () => locations.isNotEmpty ? locations.first : throw StateError('No locations'),
  );
});

/// Provider for the current member's location
/// This is the main location context for members (non-admin users)
final memberLocationProvider = FutureProvider<Location?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    final supabase = Supabase.instance.client;

    // First, get the member record for this user
    final memberResponse = await supabase
        .from('members')
        .select('location_id')
        .eq('profile_id', user.id)
        .maybeSingle();

    String? locationId = memberResponse?['location_id'] as String?;

    // If no member record by profile_id, try by email
    if (locationId == null) {
      final email = user.email;
      if (email != null) {
        // Get organization_id from profile
        final profileResponse = await supabase
            .from('profiles')
            .select('organization_id')
            .eq('id', user.id)
            .maybeSingle();

        final organizationId = profileResponse?['organization_id'] as String?;

        if (organizationId != null) {
          final memberByEmail = await supabase
              .from('members')
              .select('location_id')
              .eq('email', email)
              .eq('organization_id', organizationId)
              .maybeSingle();

          locationId = memberByEmail?['location_id'] as String?;
        }
      }
    }

    if (locationId == null) {
      debugPrint('memberLocationProvider: No location_id found for user');
      return null;
    }

    // Now fetch the location
    final locationResponse = await supabase
        .from('locations')
        .select()
        .eq('id', locationId)
        .maybeSingle();

    if (locationResponse == null) {
      debugPrint('memberLocationProvider: Location not found for id: $locationId');
      return null;
    }

    final location = Location.fromJson(locationResponse);
    debugPrint('memberLocationProvider: Found location: ${location.name}');
    return location;
  } catch (e) {
    debugPrint('memberLocationProvider: Error fetching location: $e');
    return null;
  }
});

/// Provider for the current user's effective location
/// - For members: their assigned location
/// - For staff without member record: primary location
/// - For admin: primary location (can switch via admin tools)
final currentLocationProvider = FutureProvider<Location?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;

  // Try to get member's location first
  final memberLocation = await ref.watch(memberLocationProvider.future);
  if (memberLocation != null) {
    return memberLocation;
  }

  // If no member location, fall back to primary location (for staff)
  if (profile.isStaff) {
    try {
      return await ref.watch(primaryLocationProvider.future);
    } catch (e) {
      debugPrint('currentLocationProvider: Error getting primary location: $e');
      return null;
    }
  }

  return null;
});

/// Provider for current location name (for display in UI)
final currentLocationNameProvider = Provider<String?>((ref) {
  final locationAsync = ref.watch(currentLocationProvider);
  return locationAsync.maybeWhen(
    data: (location) => location?.name,
    orElse: () => null,
  );
});

/// Provider for current location ID (for filtering queries)
final currentLocationIdProvider = Provider<String?>((ref) {
  final locationAsync = ref.watch(currentLocationProvider);
  return locationAsync.maybeWhen(
    data: (location) => location?.id,
    orElse: () => null,
  );
});

/// Provider to check if organization has multiple locations
final hasMultipleLocationsProvider = Provider<bool>((ref) {
  final locationsAsync = ref.watch(organizationLocationsProvider);
  return locationsAsync.maybeWhen(
    data: (locations) => locations.length > 1,
    orElse: () => false,
  );
});

/// Provider to check if current user can switch locations
/// Only admins can switch locations in Phase 1
final canSwitchLocationProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final hasMultiple = ref.watch(hasMultipleLocationsProvider);

  // Only admin can switch, and only if there are multiple locations
  return (profile?.isAdmin ?? false) && hasMultiple;
});

// =============================================================================
// ADMIN LOCATION CONTEXT (Phase 2 - For admin switcher)
// =============================================================================

/// State provider for admin's active location selection
/// This is separate from member's location - used only in admin tools
final adminActiveLocationIdProvider = StateProvider<String?>((ref) {
  // Default to null (will use primary location)
  return null;
});

/// Provider for admin's effective active location
/// Returns the selected location or falls back to primary
final adminActiveLocationProvider = FutureProvider<Location?>((ref) async {
  final selectedId = ref.watch(adminActiveLocationIdProvider);
  final locations = await ref.watch(organizationLocationsProvider.future);

  if (locations.isEmpty) return null;

  if (selectedId != null) {
    final selected = locations.where((l) => l.id == selectedId).firstOrNull;
    if (selected != null) return selected;
  }

  // Fall back to primary location
  return locations.firstWhere(
    (l) => l.isPrimary,
    orElse: () => locations.first,
  );
});

/// Provider for admin's active location name
final adminActiveLocationNameProvider = Provider<String?>((ref) {
  final locationAsync = ref.watch(adminActiveLocationProvider);
  return locationAsync.maybeWhen(
    data: (location) => location?.name,
    orElse: () => null,
  );
});

/// Provider to check if admin is in "All Locations" mode
/// In Phase 1, this is always false (no all-locations mode in mobile)
final isAllLocationsModeProvider = Provider<bool>((ref) {
  // Phase 1: No "All Locations" mode in mobile
  // This will be useful in Phase 2 if we add read-only all-sedes view
  return false;
});
