/// Organization settings model including booking limits.
///
/// WEB Contract Reference:
/// - Field: max_classes_per_day (organizations table)
/// - Valid range: 1-10, NULL = unlimited
/// - Timezone: organization's timezone for daily calculations

/// Organization booking limits settings
class OrganizationBookingLimits {
  const OrganizationBookingLimits({
    required this.organizationId,
    this.maxClassesPerDay,
    required this.timezone,
  });

  final String organizationId;

  /// Maximum classes per member per day. NULL = unlimited.
  /// Valid range: 1-10 (matching WEB contract)
  final int? maxClassesPerDay;

  /// Organization timezone for daily boundary calculations
  /// Default: America/Mexico_City (matching WEB)
  final String timezone;

  /// Check if there's a daily limit configured
  bool get hasLimit => maxClassesPerDay != null;

  /// Default settings (no limit)
  static const OrganizationBookingLimits defaultSettings = OrganizationBookingLimits(
    organizationId: '',
    maxClassesPerDay: null,
    timezone: 'America/Mexico_City',
  );

  factory OrganizationBookingLimits.fromJson(Map<String, dynamic> json) {
    return OrganizationBookingLimits(
      organizationId: json['id'] as String? ?? '',
      maxClassesPerDay: json['max_classes_per_day'] as int?,
      timezone: json['timezone'] as String? ?? 'America/Mexico_City',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': organizationId,
        'max_classes_per_day': maxClassesPerDay,
        'timezone': timezone,
      };

  @override
  String toString() =>
      'OrganizationBookingLimits(orgId: $organizationId, maxClassesPerDay: $maxClassesPerDay, timezone: $timezone)';
}
