import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/location.dart';

/// Repository for fetching location data from Supabase
class LocationRepository {
  LocationRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Get organization ID from current user's profile
  Future<String?> _getOrganizationId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organization_id'] as String?;
    } catch (e) {
      debugPrint('LocationRepository: Error getting organization_id: $e');
      return null;
    }
  }

  /// Get all active locations for the current user's organization
  Future<List<Location>> getLocations() async {
    try {
      final organizationId = await _getOrganizationId();
      if (organizationId == null) {
        debugPrint('LocationRepository: No organization_id found');
        return [];
      }

      final response = await _supabase
          .from('locations')
          .select()
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .order('is_primary', ascending: false)
          .order('name', ascending: true);

      final locations = (response as List)
          .map((json) => Location.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('LocationRepository: Found ${locations.length} locations');
      return locations;
    } catch (e) {
      debugPrint('LocationRepository: Error fetching locations: $e');
      return [];
    }
  }

  /// Get a single location by ID
  Future<Location?> getLocationById(String locationId) async {
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .eq('id', locationId)
          .maybeSingle();

      if (response == null) return null;

      return Location.fromJson(response);
    } catch (e) {
      debugPrint('LocationRepository: Error fetching location $locationId: $e');
      return null;
    }
  }

  /// Get the primary location for the current user's organization
  Future<Location?> getPrimaryLocation() async {
    try {
      final organizationId = await _getOrganizationId();
      if (organizationId == null) return null;

      final response = await _supabase
          .from('locations')
          .select()
          .eq('organization_id', organizationId)
          .eq('is_primary', true)
          .maybeSingle();

      if (response == null) return null;

      return Location.fromJson(response);
    } catch (e) {
      debugPrint('LocationRepository: Error fetching primary location: $e');
      return null;
    }
  }

  /// Get the location for a specific member
  Future<Location?> getMemberLocation(String memberId) async {
    try {
      // First get the member's location_id
      final memberResponse = await _supabase
          .from('members')
          .select('location_id')
          .eq('id', memberId)
          .maybeSingle();

      if (memberResponse == null) return null;

      final locationId = memberResponse['location_id'] as String?;
      if (locationId == null) return null;

      return getLocationById(locationId);
    } catch (e) {
      debugPrint('LocationRepository: Error fetching member location: $e');
      return null;
    }
  }

  /// Get location count for organization (for plan limits)
  Future<int> getLocationCount() async {
    try {
      final organizationId = await _getOrganizationId();
      if (organizationId == null) return 0;

      final response = await _supabase
          .from('locations')
          .select()
          .eq('organization_id', organizationId)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      debugPrint('LocationRepository: Error counting locations: $e');
      return 0;
    }
  }
}
