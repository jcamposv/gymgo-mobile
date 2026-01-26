import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/membership_models.dart';

/// Repository for membership operations
/// Fetches membership status and payment history from Supabase
class MembershipRepository {
  MembershipRepository(this._client);

  final SupabaseClient _client;

  /// Get the current user's member context (organization and member ID)
  Future<({String organizationId, String memberId})?> _getMemberContext() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      // Get organization and email from profile
      final profileResponse = await _client
          .from('profiles')
          .select('organization_id, email')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) return null;

      final organizationId = profileResponse['organization_id'] as String?;
      final email = profileResponse['email'] as String?;

      if (organizationId == null) return null;

      // First try to find member by user_id
      var memberResponse = await _client
          .from('members')
          .select('id')
          .eq('user_id', user.id)
          .eq('organization_id', organizationId)
          .maybeSingle();

      // If not found by user_id, try by email (for admin users or pre-linked members)
      if (memberResponse == null && email != null) {
        memberResponse = await _client
            .from('members')
            .select('id')
            .eq('email', email)
            .eq('organization_id', organizationId)
            .maybeSingle();
      }

      if (memberResponse == null) return null;

      final memberId = memberResponse['id'] as String;
      return (organizationId: organizationId, memberId: memberId);
    } catch (e) {
      debugPrint('MembershipRepository: Error getting member context: $e');
      return null;
    }
  }

  /// Get current membership information for the logged-in user
  Future<MembershipInfo?> getMembershipInfo() async {
    final context = await _getMemberContext();
    if (context == null) {
      debugPrint('MembershipRepository: No member context found');
      return null;
    }

    try {
      // Get member with plan details
      final response = await _client
          .from('members')
          .select('''
            id,
            full_name,
            membership_status,
            current_plan_id,
            membership_start_date,
            membership_end_date,
            plan:membership_plans(id, name)
          ''')
          .eq('id', context.memberId)
          .eq('organization_id', context.organizationId)
          .maybeSingle();

      if (response == null) {
        debugPrint('MembershipRepository: Member not found');
        return null;
      }

      // Calculate days remaining
      int? daysRemaining;
      final endDateStr = response['membership_end_date'] as String?;
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        final today = DateTime.now();
        daysRemaining = endDate.difference(today).inDays;
      }

      // Determine if user can book
      final status = response['membership_status'] as String?;
      final canBook = status == 'active' || status == 'expiring_soon';

      return MembershipInfo(
        memberId: response['id'] as String,
        memberName: response['full_name'] as String? ?? '',
        status: MembershipStatusExtension.fromString(status ?? 'no_membership'),
        planId: response['current_plan_id'] as String?,
        planName: response['plan']?['name'] as String?,
        startDate: response['membership_start_date'] != null
            ? DateTime.tryParse(response['membership_start_date'] as String)
            : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
        daysRemaining: daysRemaining,
        canBook: canBook,
      );
    } catch (e) {
      debugPrint('MembershipRepository: Error getting membership info: $e');
      rethrow;
    }
  }

  /// Get payment history for the logged-in user
  /// Returns payments ordered by date (most recent first)
  Future<List<PaymentRecord>> getPaymentHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final context = await _getMemberContext();
    if (context == null) {
      debugPrint('MembershipRepository: No member context found');
      return [];
    }

    try {
      final response = await _client
          .from('payments')
          .select('''
            id,
            amount,
            currency,
            status,
            payment_method,
            notes,
            created_at,
            plan_id,
            plan:membership_plans(id, name)
          ''')
          .eq('member_id', context.memberId)
          .eq('organization_id', context.organizationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PaymentRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MembershipRepository: Error getting payment history: $e');
      rethrow;
    }
  }

  /// Get available membership plans for the organization
  Future<List<MembershipPlan>> getAvailablePlans() async {
    final context = await _getMemberContext();
    if (context == null) {
      debugPrint('MembershipRepository: No member context found');
      return [];
    }

    try {
      final response = await _client
          .from('membership_plans')
          .select('*')
          .eq('organization_id', context.organizationId)
          .eq('is_active', true)
          .order('price', ascending: true);

      return (response as List)
          .map((json) => MembershipPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MembershipRepository: Error getting plans: $e');
      rethrow;
    }
  }

  /// Check if the user can make a booking (membership is active)
  /// Throws MembershipExpiredException if membership is expired
  Future<bool> canMakeBooking() async {
    final membership = await getMembershipInfo();

    if (membership == null) {
      throw const MembershipExpiredException(
        'No se encontró información de membresía.',
      );
    }

    if (membership.status == MembershipStatus.expired) {
      throw MembershipExpiredException(
        'Tu membresía venció el ${_formatDate(membership.endDate)}. '
        'Renueva para poder reservar clases.',
      );
    }

    if (membership.status == MembershipStatus.noMembership) {
      throw const MembershipExpiredException(
        'No tienes una membresía activa. Adquiere un plan para reservar clases.',
      );
    }

    return true;
  }

  /// Get gym contact information for membership inquiries
  Future<Map<String, String?>> getGymContactInfo() async {
    final context = await _getMemberContext();
    if (context == null) return {};

    try {
      final response = await _client
          .from('organizations')
          .select('name, contact_email, contact_phone, whatsapp_number')
          .eq('id', context.organizationId)
          .maybeSingle();

      if (response == null) return {};

      return {
        'name': response['name'] as String?,
        'email': response['contact_email'] as String?,
        'phone': response['contact_phone'] as String?,
        'whatsapp': response['whatsapp_number'] as String?,
      };
    } catch (e) {
      debugPrint('MembershipRepository: Error getting gym contact: $e');
      return {};
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
