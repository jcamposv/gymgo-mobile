/// Model representing gym branding configuration
class GymBranding {
  const GymBranding({
    required this.organizationId,
    required this.gymName,
    this.logoUrl,
    this.primaryColor,
    this.accentColor,
  });

  final String organizationId;
  final String gymName;
  final String? logoUrl;
  final String? primaryColor;
  final String? accentColor;

  /// Default branding when no gym is configured
  static const GymBranding defaultBranding = GymBranding(
    organizationId: '',
    gymName: 'GymGo',
    logoUrl: null,
    primaryColor: null,
    accentColor: null,
  );

  /// Whether this gym has a custom logo
  bool get hasCustomLogo => logoUrl != null && logoUrl!.isNotEmpty;

  /// Create from Supabase response
  factory GymBranding.fromJson(Map<String, dynamic> json) {
    return GymBranding(
      organizationId: json['id'] as String? ?? '',
      gymName: json['name'] as String? ?? 'GymGo',
      logoUrl: json['logo_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      accentColor: json['accent_color'] as String?,
    );
  }

  GymBranding copyWith({
    String? organizationId,
    String? gymName,
    String? logoUrl,
    String? primaryColor,
    String? accentColor,
  }) {
    return GymBranding(
      organizationId: organizationId ?? this.organizationId,
      gymName: gymName ?? this.gymName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
