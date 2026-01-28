import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/gym_class.dart';
import '../domain/booking_limit.dart';
import '../../../shared/data/organization_settings_repository.dart';
import '../../membership/domain/membership_models.dart';
import 'booking_limit_service.dart';

/// Repository for class/reservation operations with Supabase
/// Uses the schema: classes, bookings, members tables
class ClassesRepository {
  ClassesRepository(this._supabase, {OrganizationSettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? OrganizationSettingsRepository(_supabase);

  final SupabaseClient _supabase;
  final OrganizationSettingsRepository _settingsRepository;

  /// Get the booking limit service
  BookingLimitService get _bookingLimitService =>
      BookingLimitService(_supabase, _settingsRepository);

  /// Get the organization ID for the current user from profiles
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
      debugPrint('ClassesRepository._getOrganizationId error: $e');
      return null;
    }
  }

  /// Get the member ID for the current user (may be null for non-member staff)
  /// Checks both profile_id and user_id to handle different member linking methods
  Future<String?> _getMemberId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // First try by profile_id (preferred - matches currentMemberProvider logic)
      var response = await _supabase
          .from('members')
          .select('id')
          .eq('profile_id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('ClassesRepository._getMemberId: Found by profile_id');
        return response['id'] as String?;
      }

      // Fallback: try by user_id
      response = await _supabase
          .from('members')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('ClassesRepository._getMemberId: Found by user_id');
        return response['id'] as String?;
      }

      debugPrint('ClassesRepository._getMemberId: No member found');
      return null;
    } catch (e) {
      debugPrint('ClassesRepository._getMemberId error: $e');
      return null;
    }
  }

  /// Validate that member has an active membership for booking
  /// Throws [MembershipExpiredException] if membership is expired or inactive
  Future<void> _validateMembershipForBooking(String memberId) async {
    try {
      final memberData = await _supabase
          .from('members')
          .select('membership_status, membership_end_date')
          .eq('id', memberId)
          .single();

      final status = memberData['membership_status'] as String?;
      final endDateStr = memberData['membership_end_date'] as String?;

      // Check if membership is active or expiring_soon (both can book)
      if (status == 'expired') {
        String message = 'Tu membresía ha vencido.';
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          final formatted = '${endDate.day.toString().padLeft(2, '0')}/'
              '${endDate.month.toString().padLeft(2, '0')}/'
              '${endDate.year}';
          message = 'Tu membresía venció el $formatted.';
        }
        throw MembershipExpiredException('$message Renueva para poder reservar clases.');
      }

      if (status == 'no_membership' || status == null) {
        throw const MembershipExpiredException(
          'No tienes una membresía activa. Adquiere un plan para reservar clases.',
        );
      }

      // 'active' and 'expiring_soon' statuses are allowed to book
      debugPrint('ClassesRepository: Membership status=$status - booking allowed');
    } catch (e) {
      if (e is MembershipExpiredException) rethrow;
      debugPrint('ClassesRepository._validateMembershipForBooking error: $e');
      // Don't block booking if we can't verify status (fail open for now)
    }
  }

  /// Get classes for a specific date
  /// Works for both members and admin/staff (who may not have member records)
  ///
  /// [orgId] - Optional. If provided, uses this instead of querying profiles.
  /// This is preferred when the org ID is already available from a provider.
  Future<List<GymClass>> getClassesByDate(DateTime date, {String? organizationId}) async {
    // Use provided organizationId or fallback to query
    final orgId = organizationId ?? await _getOrganizationId();
    final memberId = await _getMemberId();

    debugPrint('getClassesByDate: orgId=$orgId, memberId=$memberId, date=$date');

    if (orgId == null) {
      debugPrint('getClassesByDate: No organization ID found');
      throw Exception('No hay sesion activa o no perteneces a una organizacion');
    }

    // Create date range for the selected day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get classes for the date with bookings and member info (for avatars)
    // Filter by organization_id to match web contract
    // Use explicit FK reference: members!bookings_member_id_fkey
    final classesResponse = await _supabase
        .from('classes')
        .select('''
          *,
          bookings(
            id,
            member_id,
            status,
            members!bookings_member_id_fkey(
              id,
              full_name,
              avatar_url
            )
          )
        ''')
        .eq('organization_id', orgId)
        .gte('start_time', startOfDay.toIso8601String())
        .lt('start_time', endOfDay.toIso8601String())
        .eq('is_cancelled', false)
        .order('start_time', ascending: true);

    debugPrint('getClassesByDate: Found ${classesResponse.length} classes');

    final classes = <GymClass>[];

    for (final classJson in classesResponse) {
      final bookings = classJson['bookings'] as List<dynamic>? ?? [];
      debugPrint('getClassesByDate: Class ${classJson['name']} has ${bookings.length} total bookings');

      // Filter only confirmed bookings (not cancelled)
      final confirmedBookings = bookings.where((b) {
        final status = b['status'] as String?;
        return status == 'confirmed' || status == 'attended';
      }).toList();

      debugPrint('getClassesByDate: ${confirmedBookings.length} confirmed bookings');

      // Use confirmed bookings count (more reliable than trigger)
      final currentParticipants = confirmedBookings.length;

      // Check if current user has booked
      final isUserBooked = memberId != null &&
          confirmedBookings.any((b) => b['member_id'] == memberId);

      debugPrint('getClassesByDate: isUserBooked = $isUserBooked');

      // Extract participant info from bookings
      final participants = <ClassParticipant>[];
      final participantAvatars = <String>[];
      for (final booking in confirmedBookings) {
        // Supabase returns nested relations - try both singular and plural names
        final memberData = booking['members'] as Map<String, dynamic>? ??
            booking['member'] as Map<String, dynamic>?;

        debugPrint('getClassesByDate: Booking member data: $memberData');

        if (memberData != null) {
          final avatarUrl = memberData['avatar_url'] as String?;
          debugPrint('getClassesByDate: Found member avatar_url: $avatarUrl');

          final participant = ClassParticipant.fromAvatarUrl(
            memberId: booking['member_id'] as String,
            name: memberData['full_name'] as String? ?? 'Miembro',
            avatarUrl: avatarUrl,
          );
          participants.add(participant);
          if (participant.hasAvatar) {
            // Store original URL for backwards compatibility
            if (avatarUrl != null && avatarUrl.isNotEmpty) {
              participantAvatars.add(avatarUrl);
            }
          }
        } else {
          // Member data not found in join, add placeholder
          debugPrint('getClassesByDate: No member data for booking ${booking['id']}');
          participants.add(ClassParticipant.fromAvatarUrl(
            memberId: booking['member_id'] as String,
            name: 'Miembro',
            avatarUrl: null,
          ));
        }
      }

      // Parse timestamps
      final startTime = DateTime.parse(classJson['start_time'] as String);
      final endTime = DateTime.parse(classJson['end_time'] as String);

      final gymClass = GymClass(
        id: classJson['id'] as String,
        name: classJson['name'] as String,
        instructorId: classJson['instructor_id'] as String? ?? '',
        instructorName: classJson['instructor_name'] as String? ?? 'Instructor',
        location: classJson['location'] as String? ?? 'Sala principal',
        date: startTime,
        startTime: _formatTime(startTime),
        endTime: _formatTime(endTime),
        maxCapacity: classJson['max_capacity'] as int? ?? 20,
        currentParticipants: currentParticipants,
        participantAvatars: participantAvatars,
        participants: participants,
        isUserBooked: isUserBooked,
        description: classJson['description'] as String?,
      );

      classes.add(gymClass);
    }

    return classes;
  }

  /// Reserve a spot in a class
  ///
  /// Validates:
  /// 1. User is authenticated as a member
  /// 2. Membership is active (not expired)
  /// 3. Class has capacity
  /// 4. User doesn't already have a booking
  /// 5. Daily booking limit not exceeded (WEB contract)
  ///
  /// Throws [MembershipExpiredException] if membership is expired.
  /// Throws [DailyClassLimitException] if daily limit is reached.
  Future<void> reserveClass(String classId) async {
    final memberId = await _getMemberId();
    if (memberId == null) {
      throw Exception('Usuario no autenticado o no es miembro');
    }

    // Check membership status before allowing booking
    await _validateMembershipForBooking(memberId);

    // Get class info including start_time for daily limit check
    final classData = await _supabase
        .from('classes')
        .select('max_capacity, current_bookings, organization_id, start_time')
        .eq('id', classId)
        .single();

    final maxCapacity = classData['max_capacity'] as int? ?? 20;
    final currentBookings = classData['current_bookings'] as int? ?? 0;
    final organizationId = classData['organization_id'] as String;
    final classStartTime = DateTime.parse(classData['start_time'] as String);

    if (currentBookings >= maxCapacity) {
      throw Exception('La clase está llena');
    }

    // Check if user already has an active booking
    final existingActiveBooking = await _supabase
        .from('bookings')
        .select()
        .eq('class_id', classId)
        .eq('member_id', memberId)
        .neq('status', 'cancelled')
        .maybeSingle();

    if (existingActiveBooking != null) {
      throw Exception('Ya tienes una reserva para esta clase');
    }

    // Check if there's a cancelled booking we can reactivate
    final existingCancelledBooking = await _supabase
        .from('bookings')
        .select()
        .eq('class_id', classId)
        .eq('member_id', memberId)
        .eq('status', 'cancelled')
        .maybeSingle();

    // --- DAILY LIMIT VALIDATION (WEB Contract) ---
    final limitCheck = await _bookingLimitService.checkDailyLimit(
      memberId: memberId,
      organizationId: organizationId,
      classStartTime: classStartTime,
    );

    if (!limitCheck.canBook) {
      debugPrint('ClassesRepository: Daily limit reached - ${limitCheck.currentCount}/${limitCheck.limit}');
      throw DailyClassLimitException(
        code: BookingErrorCodes.dailyClassLimitReached,
        limit: limitCheck.limit!,
        currentCount: limitCheck.currentCount,
        targetDate: limitCheck.targetDate,
        timezone: limitCheck.timezone,
        existingBookings: limitCheck.existingBookings,
      );
    }

    if (existingCancelledBooking != null) {
      // Reactivate the cancelled booking
      await _supabase
          .from('bookings')
          .update({
            'status': 'confirmed',
            'cancelled_at': null,
          })
          .eq('id', existingCancelledBooking['id'] as String);
    } else {
      // Create new booking
      await _supabase.from('bookings').insert({
        'organization_id': organizationId,
        'class_id': classId,
        'member_id': memberId,
        'status': 'confirmed',
      });
    }
  }

  /// Reserve a class on behalf of a member (Staff/Admin only).
  ///
  /// Used by ADMIN/ASSISTANT/INSTRUCTOR to add members to classes.
  /// Subject to same daily limit validation unless [bypassDailyLimit] is true.
  ///
  /// NOTE: bypassDailyLimit exists for parity with WEB but is NOT used in UI
  /// per WEB contract analysis.
  Future<void> reserveClassForMember({
    required String classId,
    required String memberId,
    bool bypassDailyLimit = false,
  }) async {
    // Get class info
    final classData = await _supabase
        .from('classes')
        .select('max_capacity, current_bookings, organization_id, start_time')
        .eq('id', classId)
        .single();

    final maxCapacity = classData['max_capacity'] as int? ?? 20;
    final currentBookings = classData['current_bookings'] as int? ?? 0;
    final organizationId = classData['organization_id'] as String;
    final classStartTime = DateTime.parse(classData['start_time'] as String);

    if (currentBookings >= maxCapacity) {
      throw Exception('La clase está llena');
    }

    // Check if member already has an active booking
    final existingActiveBooking = await _supabase
        .from('bookings')
        .select()
        .eq('class_id', classId)
        .eq('member_id', memberId)
        .neq('status', 'cancelled')
        .maybeSingle();

    if (existingActiveBooking != null) {
      throw Exception('El miembro ya tiene una reserva para esta clase');
    }

    // Check if there's a cancelled booking we can reactivate
    final existingCancelledBooking = await _supabase
        .from('bookings')
        .select()
        .eq('class_id', classId)
        .eq('member_id', memberId)
        .eq('status', 'cancelled')
        .maybeSingle();

    // --- DAILY LIMIT VALIDATION (WEB Contract) ---
    // Only check if not bypassing (matching WEB behavior)
    if (!bypassDailyLimit) {
      final limitCheck = await _bookingLimitService.checkDailyLimit(
        memberId: memberId,
        organizationId: organizationId,
        classStartTime: classStartTime,
      );

      if (!limitCheck.canBook) {
        debugPrint('ClassesRepository: Daily limit reached for member - ${limitCheck.currentCount}/${limitCheck.limit}');
        throw DailyClassLimitException(
          code: BookingErrorCodes.dailyClassLimitReached,
          limit: limitCheck.limit!,
          currentCount: limitCheck.currentCount,
          targetDate: limitCheck.targetDate,
          timezone: limitCheck.timezone,
          existingBookings: limitCheck.existingBookings,
          message: 'El miembro ya tiene ${limitCheck.currentCount} clases reservadas para este día (máximo: ${limitCheck.limit})',
        );
      }
    }

    if (existingCancelledBooking != null) {
      // Reactivate the cancelled booking
      await _supabase
          .from('bookings')
          .update({
            'status': 'confirmed',
            'cancelled_at': null,
          })
          .eq('id', existingCancelledBooking['id'] as String);
    } else {
      // Create new booking
      await _supabase.from('bookings').insert({
        'organization_id': organizationId,
        'class_id': classId,
        'member_id': memberId,
        'status': 'confirmed',
      });
    }
  }

  /// Cancel a reservation
  Future<void> cancelReservation(String classId) async {
    final memberId = await _getMemberId();
    if (memberId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Update booking status to cancelled
    await _supabase
        .from('bookings')
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toIso8601String(),
        })
        .eq('class_id', classId)
        .eq('member_id', memberId)
        .neq('status', 'cancelled');
  }

  /// Get user's bookings for a date range
  Future<List<ClassReservation>> getUserReservations({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final memberId = await _getMemberId();
    if (memberId == null) return [];

    final response = await _supabase
        .from('bookings')
        .select()
        .eq('member_id', memberId)
        .neq('status', 'cancelled');

    return (response as List<dynamic>)
        .map((json) => ClassReservation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get next upcoming class for the user
  Future<GymClass?> getNextUserClass() async {
    final memberId = await _getMemberId();
    if (memberId == null) {
      debugPrint('getNextUserClass: No member ID found for user');
      return null;
    }

    debugPrint('getNextUserClass: Member ID = $memberId');

    try {
      // Get all bookings for the member (simplified query)
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            status,
            class_id,
            classes (
              id,
              name,
              instructor_id,
              instructor_name,
              location,
              start_time,
              end_time,
              max_capacity,
              current_bookings
            )
          ''')
          .eq('member_id', memberId)
          .inFilter('status', ['confirmed', 'attended']);

      debugPrint('getNextUserClass: Found ${response.length} bookings');

      if (response.isEmpty) {
        debugPrint('getNextUserClass: No bookings found');
        return null;
      }

      final now = DateTime.now();
      GymClass? nextClass;
      DateTime? earliestStart;

      // Find the next upcoming class
      for (final booking in response) {
        debugPrint('getNextUserClass: Booking status = ${booking['status']}');

        final classData = booking['classes'];
        if (classData == null) {
          debugPrint('getNextUserClass: No class data for booking');
          continue;
        }

        debugPrint('getNextUserClass: Class = ${classData['name']}');

        final startTimeStr = classData['start_time'] as String?;
        if (startTimeStr == null) continue;

        final startTime = DateTime.parse(startTimeStr);
        debugPrint('getNextUserClass: Class start_time = $startTime, now = $now');

        // Only consider future classes
        if (startTime.isAfter(now)) {
          if (earliestStart == null || startTime.isBefore(earliestStart)) {
            earliestStart = startTime;
            final endTime = DateTime.parse(classData['end_time'] as String);

            nextClass = GymClass(
              id: classData['id'] as String,
              name: classData['name'] as String,
              instructorId: classData['instructor_id'] as String? ?? '',
              instructorName: classData['instructor_name'] as String? ?? 'Instructor',
              location: classData['location'] as String? ?? 'Sala principal',
              date: startTime,
              startTime: _formatTime(startTime),
              endTime: _formatTime(endTime),
              maxCapacity: classData['max_capacity'] as int? ?? 20,
              currentParticipants: classData['current_bookings'] as int? ?? 0,
              isUserBooked: true,
            );
          }
        } else {
          debugPrint('getNextUserClass: Class is in the past, skipping');
        }
      }

      if (nextClass != null) {
        debugPrint('getNextUserClass: Returning next class = ${nextClass.name}');
      } else {
        debugPrint('getNextUserClass: No future classes found');
      }

      return nextClass;
    } catch (e, stack) {
      debugPrint('getNextUserClass error: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  /// Format DateTime to HH:mm string
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
