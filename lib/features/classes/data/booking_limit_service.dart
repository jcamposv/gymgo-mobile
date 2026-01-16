import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/booking_limit.dart';
import '../../../shared/data/organization_settings_repository.dart';

/// Service for checking daily booking limits.
///
/// WEB Contract Reference:
/// - RPC: can_member_book_class(p_member_id, p_organization_id, p_class_start_time, p_exclude_booking_id)
/// - RPC: get_member_daily_booking_count(p_member_id, p_organization_id, p_target_date, p_timezone, p_exclude_booking_id)
/// - Counting statuses: confirmed, waitlist, attended, no_show (NOT cancelled)
class BookingLimitService {
  BookingLimitService(this._supabase, this._settingsRepository);

  final SupabaseClient _supabase;
  final OrganizationSettingsRepository _settingsRepository;

  /// Check if a member can book a class based on daily limits.
  ///
  /// Returns [DailyLimitCheckResult] with canBook=true if allowed,
  /// or canBook=false with details about existing bookings.
  ///
  /// Parameters:
  /// - [memberId]: The member's ID
  /// - [organizationId]: The organization ID
  /// - [classStartTime]: The start time of the class being booked
  /// - [excludeBookingId]: Optional booking ID to exclude (for reschedule)
  Future<DailyLimitCheckResult> checkDailyLimit({
    required String memberId,
    required String organizationId,
    required DateTime classStartTime,
    String? excludeBookingId,
  }) async {
    try {
      // Get organization settings
      final settings = await _settingsRepository.getBookingLimitsForOrg(organizationId);

      // If no limit is configured, allow booking
      if (!settings.hasLimit) {
        debugPrint('BookingLimitService: No daily limit configured');
        return DailyLimitCheckResult.unlimited();
      }

      debugPrint('BookingLimitService: Limit is ${settings.maxClassesPerDay} per day');

      // Calculate the target date in the organization's timezone
      final targetDate = _formatDateInTimezone(classStartTime, settings.timezone);
      debugPrint('BookingLimitService: Target date is $targetDate (timezone: ${settings.timezone})');

      // Get the member's booking count for that day
      final existingBookings = await _getMemberDailyBookings(
        memberId: memberId,
        organizationId: organizationId,
        targetDate: targetDate,
        timezone: settings.timezone,
        excludeBookingId: excludeBookingId,
      );

      final currentCount = existingBookings.length;
      final canBook = currentCount < settings.maxClassesPerDay!;

      debugPrint('BookingLimitService: Current count = $currentCount, canBook = $canBook');

      return DailyLimitCheckResult(
        canBook: canBook,
        currentCount: currentCount,
        limit: settings.maxClassesPerDay,
        targetDate: targetDate,
        timezone: settings.timezone,
        existingBookings: existingBookings,
      );
    } catch (e, stack) {
      debugPrint('BookingLimitService.checkDailyLimit error: $e');
      debugPrint('Stack: $stack');
      // On error, allow booking (backend will be source of truth)
      return DailyLimitCheckResult.unlimited();
    }
  }

  /// Get member's bookings for a specific day that count toward the limit.
  ///
  /// Matching WEB: counts confirmed, waitlist, attended, no_show (NOT cancelled)
  Future<List<DailyBookingInfo>> _getMemberDailyBookings({
    required String memberId,
    required String organizationId,
    required String targetDate,
    required String timezone,
    String? excludeBookingId,
  }) async {
    try {
      // Calculate day boundaries in UTC based on timezone
      final dayBounds = _getDayBoundsInTimezone(targetDate, timezone);

      // Query bookings for the day with counting statuses
      var query = _supabase
          .from('bookings')
          .select('''
            id,
            status,
            classes (
              id,
              name,
              start_time
            )
          ''')
          .eq('member_id', memberId)
          .eq('organization_id', organizationId)
          .inFilter('status', BookingCountingStatuses.countingStatuses);

      // Exclude a specific booking (for reschedule scenarios)
      if (excludeBookingId != null) {
        query = query.neq('id', excludeBookingId);
      }

      final response = await query;

      // Filter by class start time being within the day bounds
      final bookings = <DailyBookingInfo>[];
      for (final booking in response) {
        final classData = booking['classes'];
        if (classData == null) continue;

        final classStartTime = DateTime.parse(classData['start_time'] as String);

        // Check if class is within the target day
        if (classStartTime.isAfter(dayBounds.start) &&
            classStartTime.isBefore(dayBounds.end)) {
          bookings.add(DailyBookingInfo(
            id: booking['id'] as String,
            className: classData['name'] as String? ?? '',
            startTime: classData['start_time'] as String,
            status: booking['status'] as String,
          ));
        }
      }

      debugPrint('BookingLimitService: Found ${bookings.length} bookings for $targetDate');
      return bookings;
    } catch (e) {
      debugPrint('BookingLimitService._getMemberDailyBookings error: $e');
      return [];
    }
  }

  /// Format a DateTime to YYYY-MM-DD in the specified timezone.
  ///
  /// Matching WEB: formatDateInTimezone() in daily-limit.ts
  String _formatDateInTimezone(DateTime dateTime, String timezone) {
    // For mobile, we use a simplified approach
    // The timezone library would be needed for full accuracy
    // For now, we work with local time which is typically correct for
    // apps operating within the same timezone as the gym
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get the UTC bounds for a day in a specific timezone.
  ///
  /// Matching WEB: getDayBoundsInTimezone() in daily-limit.ts
  _DayBounds _getDayBoundsInTimezone(String dateStr, String timezone) {
    // Parse the date string (YYYY-MM-DD)
    final parts = dateStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    // Create start and end of day
    // Note: For full timezone support, use the timezone package
    // This simplified version works for local timezone operations
    final startOfDay = DateTime(year, month, day);
    final endOfDay = DateTime(year, month, day, 23, 59, 59, 999);

    return _DayBounds(start: startOfDay, end: endOfDay);
  }
}

/// Helper class for day boundaries
class _DayBounds {
  const _DayBounds({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// Extension to create BookingLimitService easily
extension BookingLimitServiceProvider on SupabaseClient {
  BookingLimitService createBookingLimitService(
      OrganizationSettingsRepository settingsRepository) {
    return BookingLimitService(this, settingsRepository);
  }
}
