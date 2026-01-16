import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/organization_settings.dart';

/// Repository for fetching organization settings including booking limits.
///
/// WEB Contract Reference:
/// - Table: organizations
/// - Fields: max_classes_per_day, timezone
class OrganizationSettingsRepository {
  OrganizationSettingsRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Cache for organization settings to reduce API calls
  OrganizationBookingLimits? _cachedSettings;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  /// Get organization ID for the current user
  Future<String?> _getOrganizationId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Try profiles first (for staff)
      final profileResponse = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null && profileResponse['organization_id'] != null) {
        return profileResponse['organization_id'] as String;
      }

      // Fall back to members (for regular members)
      final memberResponse = await _supabase
          .from('members')
          .select('organization_id')
          .eq('user_id', userId)
          .maybeSingle();

      return memberResponse?['organization_id'] as String?;
    } catch (e) {
      debugPrint('OrganizationSettingsRepository._getOrganizationId error: $e');
      return null;
    }
  }

  /// Get booking limits settings for the user's organization.
  ///
  /// Uses caching to reduce API calls. Cache expires after 5 minutes.
  Future<OrganizationBookingLimits> getBookingLimits({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh &&
        _cachedSettings != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      debugPrint('OrganizationSettingsRepository: Using cached settings');
      return _cachedSettings!;
    }

    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      debugPrint('OrganizationSettingsRepository: No organization ID, returning default');
      return OrganizationBookingLimits.defaultSettings;
    }

    try {
      final response = await _supabase
          .from('organizations')
          .select('id, max_classes_per_day, timezone')
          .eq('id', organizationId)
          .maybeSingle();

      if (response == null) {
        debugPrint('OrganizationSettingsRepository: No organization found');
        return OrganizationBookingLimits.defaultSettings;
      }

      final settings = OrganizationBookingLimits.fromJson(response);
      debugPrint('OrganizationSettingsRepository: Fetched settings: $settings');

      // Update cache
      _cachedSettings = settings;
      _cacheTimestamp = DateTime.now();

      return settings;
    } catch (e) {
      debugPrint('OrganizationSettingsRepository.getBookingLimits error: $e');
      return OrganizationBookingLimits.defaultSettings;
    }
  }

  /// Get booking limits for a specific organization (for admin use)
  Future<OrganizationBookingLimits> getBookingLimitsForOrg(String organizationId) async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('id, max_classes_per_day, timezone')
          .eq('id', organizationId)
          .maybeSingle();

      if (response == null) {
        return OrganizationBookingLimits.defaultSettings;
      }

      return OrganizationBookingLimits.fromJson(response);
    } catch (e) {
      debugPrint('OrganizationSettingsRepository.getBookingLimitsForOrg error: $e');
      return OrganizationBookingLimits.defaultSettings;
    }
  }

  /// Clear the settings cache (call after settings are updated)
  void clearCache() {
    _cachedSettings = null;
    _cacheTimestamp = null;
  }
}
