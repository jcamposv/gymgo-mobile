/// Member model representing a gym member
///
/// Supports three states for profile photo:
/// 1. profileImageUrl - Custom uploaded image
/// 2. avatarPath - Predefined avatar selection
/// 3. Neither - Falls back to initials
class Member {
  const Member({
    required this.id,
    required this.name,
    this.email,
    this.organizationId,
    this.locationId,
    this.profileImageUrl,
    this.avatarPath,
    this.membershipStatus,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? organizationId;
  final String? locationId;
  final String? profileImageUrl;
  final String? avatarPath;
  final String? membershipStatus;
  final DateTime? joinedAt;

  /// Get the display name initials (max 2 characters)
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Check if member has a profile image (either uploaded or avatar)
  bool get hasProfileImage =>
      (profileImageUrl != null && profileImageUrl!.isNotEmpty) ||
      (avatarPath != null && avatarPath!.isNotEmpty);

  /// Get the effective image URL based on priority
  /// Returns null if should use fallback
  String? get effectiveImageUrl {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return profileImageUrl;
    }
    return null;
  }

  /// Check if using avatar path
  bool get isUsingAvatar =>
      avatarPath != null &&
      avatarPath!.isNotEmpty &&
      (profileImageUrl == null || profileImageUrl!.isEmpty);

  /// Create a copy with updated fields
  Member copyWith({
    String? id,
    String? name,
    String? email,
    String? organizationId,
    String? locationId,
    String? profileImageUrl,
    String? avatarPath,
    String? membershipStatus,
    DateTime? joinedAt,
    bool clearProfileImageUrl = false,
    bool clearAvatarPath = false,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      organizationId: organizationId ?? this.organizationId,
      locationId: locationId ?? this.locationId,
      profileImageUrl: clearProfileImageUrl ? null : (profileImageUrl ?? this.profileImageUrl),
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      membershipStatus: membershipStatus ?? this.membershipStatus,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Create from JSON (Supabase response)
  factory Member.fromJson(Map<String, dynamic> json) {
    // Web uses avatar_url for both uploaded images and predefined avatars
    // Predefined avatars are stored as '/avatar/avatar_01.svg'
    // Uploaded images are full CDN URLs
    final avatarUrl = json['avatar_url'] as String?;

    String? profileImageUrl;
    String? avatarPath;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('/avatar/')) {
        // Predefined avatar - convert to mobile path format
        // /avatar/avatar_01.svg -> avatar_2/avatar_01.svg
        avatarPath = avatarUrl.replaceFirst('/avatar/', 'avatar_2/');
      } else if (avatarUrl.startsWith('http')) {
        // Uploaded image URL
        profileImageUrl = avatarUrl;
      }
    }

    return Member(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'Member',
      email: json['email'] as String?,
      organizationId: json['organization_id'] as String?,
      locationId: json['location_id'] as String?,
      profileImageUrl: profileImageUrl,
      avatarPath: avatarPath,
      membershipStatus: json['membership_status'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (organizationId != null) 'organization_id': organizationId,
      if (locationId != null) 'location_id': locationId,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (membershipStatus != null) 'membership_status': membershipStatus,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          organizationId == other.organizationId &&
          locationId == other.locationId &&
          profileImageUrl == other.profileImageUrl &&
          avatarPath == other.avatarPath;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      organizationId.hashCode ^
      locationId.hashCode ^
      profileImageUrl.hashCode ^
      avatarPath.hashCode;
}
