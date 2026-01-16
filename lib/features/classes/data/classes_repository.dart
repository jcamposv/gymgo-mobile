import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/gym_class.dart';

/// Repository for class/reservation operations with Supabase
/// Uses the schema: classes, bookings, members tables
class ClassesRepository {
  ClassesRepository(this._supabase);

  final SupabaseClient _supabase;

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
  Future<String?> _getMemberId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('members')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      debugPrint('ClassesRepository._getMemberId error: $e');
      return null;
    }
  }

  /// Get classes for a specific date
  /// Works for both members and admin/staff (who may not have member records)
  Future<List<GymClass>> getClassesByDate(DateTime date) async {
    final organizationId = await _getOrganizationId();
    final memberId = await _getMemberId();

    debugPrint('getClassesByDate: orgId=$organizationId, memberId=$memberId, date=$date');

    if (organizationId == null) {
      debugPrint('getClassesByDate: No organization ID found');
      throw Exception('No hay sesion activa o no perteneces a una organizacion');
    }

    // Create date range for the selected day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get classes for the date with bookings
    // Filter by organization_id to match web contract
    final classesResponse = await _supabase
        .from('classes')
        .select('''
          *,
          bookings(
            id,
            member_id,
            status
          )
        ''')
        .eq('organization_id', organizationId)
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
        participantAvatars: const [], // Simplified - avatars removed for now
        isUserBooked: isUserBooked,
        description: classJson['description'] as String?,
      );

      classes.add(gymClass);
    }

    return classes;
  }

  /// Reserve a spot in a class
  Future<void> reserveClass(String classId) async {
    final memberId = await _getMemberId();
    if (memberId == null) {
      throw Exception('Usuario no autenticado o no es miembro');
    }

    // Get class info
    final classData = await _supabase
        .from('classes')
        .select('max_capacity, current_bookings, organization_id')
        .eq('id', classId)
        .single();

    final maxCapacity = classData['max_capacity'] as int? ?? 20;
    final currentBookings = classData['current_bookings'] as int? ?? 0;
    final organizationId = classData['organization_id'] as String;

    if (currentBookings >= maxCapacity) {
      throw Exception('La clase está llena');
    }

    // Check if user already has a booking
    final existingBooking = await _supabase
        .from('bookings')
        .select()
        .eq('class_id', classId)
        .eq('member_id', memberId)
        .neq('status', 'cancelled')
        .maybeSingle();

    if (existingBooking != null) {
      throw Exception('Ya tienes una reserva para esta clase');
    }

    // Create booking
    await _supabase.from('bookings').insert({
      'organization_id': organizationId,
      'class_id': classId,
      'member_id': memberId,
      'status': 'confirmed',
    });
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
