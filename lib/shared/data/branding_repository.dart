import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/gym_branding.dart';

/// Repository for fetching gym branding information
class BrandingRepository {
  BrandingRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Get the organization branding for the current user's gym
  Future<GymBranding> getGymBranding() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return GymBranding.defaultBranding;
    }

    try {
      // First get the member's organization
      final memberResponse = await _supabase
          .from('members')
          .select('organization_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (memberResponse == null) {
        return GymBranding.defaultBranding;
      }

      final organizationId = memberResponse['organization_id'] as String?;
      if (organizationId == null) {
        return GymBranding.defaultBranding;
      }

      // Then get the organization details
      final orgResponse = await _supabase
          .from('organizations')
          .select('id, name, logo_url')
          .eq('id', organizationId)
          .maybeSingle();

      if (orgResponse == null) {
        return GymBranding.defaultBranding;
      }

      return GymBranding.fromJson(orgResponse);
    } catch (e) {
      print('Error fetching gym branding: $e');
      return GymBranding.defaultBranding;
    }
  }

  /// Get public URL for a logo stored in Supabase Storage
  String? getLogoPublicUrl(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) return null;

    // If it's already a full URL, return it
    if (logoPath.startsWith('http')) return logoPath;

    // Otherwise, get public URL from storage
    try {
      return _supabase.storage.from('logos').getPublicUrl(logoPath);
    } catch (e) {
      print('Error getting logo URL: $e');
      return null;
    }
  }
}
