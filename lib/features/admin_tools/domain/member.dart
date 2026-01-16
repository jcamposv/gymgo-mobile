/// Member status enum matching Supabase schema
enum MemberStatus {
  active,
  inactive,
  suspended,
  cancelled,
}

/// Experience level enum
enum ExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

/// Represents a gym member
class Member {
  const Member({
    required this.id,
    required this.email,
    required this.fullName,
    required this.organizationId,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.status = MemberStatus.active,
    this.experienceLevel = ExperienceLevel.beginner,
    this.currentPlanId,
    this.membershipStartDate,
    this.membershipEndDate,
    this.lastCheckIn,
    this.checkInCount = 0,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String organizationId;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final MemberStatus status;
  final ExperienceLevel experienceLevel;
  final String? currentPlanId;
  final DateTime? membershipStartDate;
  final DateTime? membershipEndDate;
  final DateTime? lastCheckIn;
  final int checkInCount;
  final DateTime? createdAt;

  /// Get display initials for avatar
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  /// Check if membership is active (has valid dates)
  bool get hasMembership {
    if (membershipStartDate == null) return false;
    final now = DateTime.now();
    if (membershipEndDate != null && membershipEndDate!.isBefore(now)) {
      return false;
    }
    return membershipStartDate!.isBefore(now) ||
           membershipStartDate!.isAtSameMomentAs(now);
  }

  /// Get status display label (Spanish)
  String get statusLabel {
    switch (status) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.inactive:
        return 'Inactivo';
      case MemberStatus.suspended:
        return 'Suspendido';
      case MemberStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Get experience level display label (Spanish)
  String get experienceLevelLabel {
    switch (experienceLevel) {
      case ExperienceLevel.beginner:
        return 'Principiante';
      case ExperienceLevel.intermediate:
        return 'Intermedio';
      case ExperienceLevel.advanced:
        return 'Avanzado';
    }
  }

  /// Create from JSON (Supabase)
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      organizationId: json['organization_id'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      status: _parseStatus(json['status'] as String?),
      experienceLevel: _parseExperienceLevel(json['experience_level'] as String?),
      currentPlanId: json['current_plan_id'] as String?,
      membershipStartDate: json['membership_start_date'] != null
          ? DateTime.tryParse(json['membership_start_date'] as String)
          : null,
      membershipEndDate: json['membership_end_date'] != null
          ? DateTime.tryParse(json['membership_end_date'] as String)
          : null,
      lastCheckIn: json['last_check_in'] != null
          ? DateTime.tryParse(json['last_check_in'] as String)
          : null,
      checkInCount: json['check_in_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static MemberStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return MemberStatus.active;
      case 'inactive':
        return MemberStatus.inactive;
      case 'suspended':
        return MemberStatus.suspended;
      case 'cancelled':
        return MemberStatus.cancelled;
      default:
        return MemberStatus.active;
    }
  }

  static ExperienceLevel _parseExperienceLevel(String? level) {
    switch (level) {
      case 'beginner':
        return ExperienceLevel.beginner;
      case 'intermediate':
        return ExperienceLevel.intermediate;
      case 'advanced':
        return ExperienceLevel.advanced;
      default:
        return ExperienceLevel.beginner;
    }
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'organization_id': organizationId,
      'phone': phone,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'status': status.name,
      'experience_level': experienceLevel.name,
      'current_plan_id': currentPlanId,
      'membership_start_date': membershipStartDate?.toIso8601String().split('T')[0],
      'membership_end_date': membershipEndDate?.toIso8601String().split('T')[0],
    };
  }

  Member copyWith({
    String? id,
    String? email,
    String? fullName,
    String? organizationId,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    MemberStatus? status,
    ExperienceLevel? experienceLevel,
    String? currentPlanId,
    DateTime? membershipStartDate,
    DateTime? membershipEndDate,
    DateTime? lastCheckIn,
    int? checkInCount,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      organizationId: organizationId ?? this.organizationId,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      currentPlanId: currentPlanId ?? this.currentPlanId,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      checkInCount: checkInCount ?? this.checkInCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
