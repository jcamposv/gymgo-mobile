/// Booking limit models and exceptions matching WEB contract.
///
/// WEB Contract Reference:
/// - Error code: DAILY_CLASS_LIMIT_REACHED
/// - Counting statuses: confirmed, waitlist, attended, no_show (NOT cancelled)
/// - Timezone: Organization's timezone (e.g., America/Mexico_City)

/// Information about an existing booking for error display
class DailyBookingInfo {
  const DailyBookingInfo({
    required this.id,
    required this.className,
    required this.startTime,
    required this.status,
  });

  final String id;
  final String className;
  final String startTime;
  final String status;

  factory DailyBookingInfo.fromJson(Map<String, dynamic> json) {
    return DailyBookingInfo(
      id: json['id'] as String,
      className: json['className'] as String? ?? json['class_name'] as String? ?? '',
      startTime: json['startTime'] as String? ?? json['start_time'] as String? ?? '',
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'className': className,
        'startTime': startTime,
        'status': status,
      };
}

/// Result of a daily booking limit check
class DailyLimitCheckResult {
  const DailyLimitCheckResult({
    required this.canBook,
    required this.currentCount,
    required this.limit,
    required this.targetDate,
    required this.timezone,
    this.existingBookings = const [],
  });

  final bool canBook;
  final int currentCount;
  final int? limit;
  final String targetDate;
  final String timezone;
  final List<DailyBookingInfo> existingBookings;

  factory DailyLimitCheckResult.fromJson(Map<String, dynamic> json) {
    final existingBookingsJson = json['existingBookings'] as List<dynamic>? ??
        json['existing_bookings'] as List<dynamic>? ??
        [];

    return DailyLimitCheckResult(
      canBook: json['canBook'] as bool? ?? json['can_book'] as bool? ?? true,
      currentCount: json['currentCount'] as int? ?? json['current_count'] as int? ?? 0,
      limit: json['limit'] as int?,
      targetDate: json['targetDate'] as String? ?? json['target_date'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'America/Mexico_City',
      existingBookings: existingBookingsJson
          .map((e) => DailyBookingInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory DailyLimitCheckResult.unlimited() {
    return const DailyLimitCheckResult(
      canBook: true,
      currentCount: 0,
      limit: null,
      targetDate: '',
      timezone: 'America/Mexico_City',
    );
  }
}

/// Error code matching WEB contract
class BookingErrorCodes {
  BookingErrorCodes._();

  static const String dailyClassLimitReached = 'DAILY_CLASS_LIMIT_REACHED';
}

/// Exception for daily class limit reached
/// Matches WEB error response structure exactly
class DailyClassLimitException implements Exception {
  const DailyClassLimitException({
    required this.code,
    required this.limit,
    required this.currentCount,
    required this.targetDate,
    required this.timezone,
    this.existingBookings = const [],
    this.message,
  });

  final String code;
  final int limit;
  final int currentCount;
  final String targetDate;
  final String timezone;
  final List<DailyBookingInfo> existingBookings;
  final String? message;

  /// Create from WEB-style error response
  factory DailyClassLimitException.fromJson(Map<String, dynamic> json) {
    final existingBookingsJson = json['existingBookings'] as List<dynamic>? ??
        json['existing_bookings'] as List<dynamic>? ??
        [];

    return DailyClassLimitException(
      code: json['code'] as String? ?? BookingErrorCodes.dailyClassLimitReached,
      limit: json['limit'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? json['current_count'] as int? ?? 0,
      targetDate: json['targetDate'] as String? ?? json['target_date'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'America/Mexico_City',
      existingBookings: existingBookingsJson
          .map((e) => DailyBookingInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }

  /// Default message matching WEB
  String get displayMessage =>
      message ?? 'Ya alcanzaste el máximo de $limit clases para hoy.';

  /// Detailed description for toast
  String get detailMessage =>
      'Tienes $currentCount de $limit clases para el $targetDate';

  @override
  String toString() => displayMessage;
}

/// Statuses that count toward daily limit (matching WEB)
class BookingCountingStatuses {
  BookingCountingStatuses._();

  /// Statuses that count toward the daily booking limit
  /// Matching WEB: ['confirmed', 'waitlist', 'attended', 'no_show']
  static const List<String> countingStatuses = [
    'confirmed',
    'waitlist',
    'attended',
    'no_show',
  ];

  /// Cancelled status does NOT count
  static const String cancelled = 'cancelled';

  /// Check if a status counts toward the limit
  static bool countsTowardLimit(String status) {
    return countingStatuses.contains(status);
  }
}
