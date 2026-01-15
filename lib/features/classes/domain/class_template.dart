/// Class template models for GymGo
/// Matches the Supabase schema from web implementation

/// Days of week constants
class DayOfWeek {
  static const int sunday = 0;
  static const int monday = 1;
  static const int tuesday = 2;
  static const int wednesday = 3;
  static const int thursday = 4;
  static const int friday = 5;
  static const int saturday = 6;

  static String getName(int day) {
    switch (day) {
      case sunday:
        return 'Domingo';
      case monday:
        return 'Lunes';
      case tuesday:
        return 'Martes';
      case wednesday:
        return 'Miércoles';
      case thursday:
        return 'Jueves';
      case friday:
        return 'Viernes';
      case saturday:
        return 'Sábado';
      default:
        return 'Desconocido';
    }
  }

  static String getShortName(int day) {
    switch (day) {
      case sunday:
        return 'Dom';
      case monday:
        return 'Lun';
      case tuesday:
        return 'Mar';
      case wednesday:
        return 'Mié';
      case thursday:
        return 'Jue';
      case friday:
        return 'Vie';
      case saturday:
        return 'Sáb';
      default:
        return '?';
    }
  }
}

/// Class type options (matches web)
class ClassType {
  static const String crossfit = 'crossfit';
  static const String yoga = 'yoga';
  static const String pilates = 'pilates';
  static const String spinning = 'spinning';
  static const String hiit = 'hiit';
  static const String strength = 'strength';
  static const String cardio = 'cardio';
  static const String functional = 'functional';
  static const String boxing = 'boxing';
  static const String mma = 'mma';
  static const String stretching = 'stretching';
  static const String openGym = 'open_gym';
  static const String personal = 'personal';
  static const String other = 'other';

  static const List<String> all = [
    crossfit,
    yoga,
    pilates,
    spinning,
    hiit,
    strength,
    cardio,
    functional,
    boxing,
    mma,
    stretching,
    openGym,
    personal,
    other,
  ];

  static String getLabel(String type) {
    switch (type) {
      case crossfit:
        return 'CrossFit';
      case yoga:
        return 'Yoga';
      case pilates:
        return 'Pilates';
      case spinning:
        return 'Spinning';
      case hiit:
        return 'HIIT';
      case strength:
        return 'Fuerza';
      case cardio:
        return 'Cardio';
      case functional:
        return 'Funcional';
      case boxing:
        return 'Box';
      case mma:
        return 'MMA';
      case stretching:
        return 'Estiramiento';
      case openGym:
        return 'Open Gym';
      case personal:
        return 'Personal';
      case other:
        return 'Otro';
      default:
        return type;
    }
  }
}

/// Class template model (matches class_templates table)
class ClassTemplate {
  const ClassTemplate({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    this.description,
    this.classType,
    this.waitlistEnabled = false,
    this.maxWaitlist = 0,
    this.instructorId,
    this.instructorName,
    this.location,
    this.bookingOpensHours = 168,
    this.bookingClosesMinutes = 60,
    this.cancellationDeadlineHours = 2,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? classType;
  final int dayOfWeek;
  final String startTime; // HH:MM format
  final String endTime; // HH:MM format
  final int maxCapacity;
  final bool waitlistEnabled;
  final int maxWaitlist;
  final String? instructorId;
  final String? instructorName;
  final String? location;
  final int bookingOpensHours;
  final int bookingClosesMinutes;
  final int cancellationDeadlineHours;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Get day name
  String get dayName => DayOfWeek.getName(dayOfWeek);

  /// Get short day name
  String get shortDayName => DayOfWeek.getShortName(dayOfWeek);

  /// Get class type label
  String get classTypeLabel =>
      classType != null ? ClassType.getLabel(classType!) : '';

  /// Get formatted time range
  String get timeRange => '$startTime - $endTime';

  /// Get duration in minutes
  int get durationMinutes {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return endMinutes - startMinutes;
  }

  factory ClassTemplate.fromJson(Map<String, dynamic> json) {
    return ClassTemplate(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      classType: json['class_type'] as String?,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      maxCapacity: json['max_capacity'] as int? ?? 20,
      waitlistEnabled: json['waitlist_enabled'] as bool? ?? false,
      maxWaitlist: json['max_waitlist'] as int? ?? 0,
      instructorId: json['instructor_id'] as String?,
      instructorName: json['instructor_name'] as String?,
      location: json['location'] as String?,
      bookingOpensHours: json['booking_opens_hours'] as int? ?? 168,
      bookingClosesMinutes: json['booking_closes_minutes'] as int? ?? 60,
      cancellationDeadlineHours:
          json['cancellation_deadline_hours'] as int? ?? 2,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'class_type': classType,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'max_capacity': maxCapacity,
      'waitlist_enabled': waitlistEnabled,
      'max_waitlist': maxWaitlist,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'location': location,
      'booking_opens_hours': bookingOpensHours,
      'booking_closes_minutes': bookingClosesMinutes,
      'cancellation_deadline_hours': cancellationDeadlineHours,
      'is_active': isActive,
    };
  }

  ClassTemplate copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    String? classType,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    bool? waitlistEnabled,
    int? maxWaitlist,
    String? instructorId,
    String? instructorName,
    String? location,
    int? bookingOpensHours,
    int? bookingClosesMinutes,
    int? cancellationDeadlineHours,
    bool? isActive,
  }) {
    return ClassTemplate(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      classType: classType ?? this.classType,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      waitlistEnabled: waitlistEnabled ?? this.waitlistEnabled,
      maxWaitlist: maxWaitlist ?? this.maxWaitlist,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      location: location ?? this.location,
      bookingOpensHours: bookingOpensHours ?? this.bookingOpensHours,
      bookingClosesMinutes: bookingClosesMinutes ?? this.bookingClosesMinutes,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// DTO for creating a class from template
class CreateClassDto {
  const CreateClassDto({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    this.description,
    this.classType,
    this.instructorId,
    this.instructorName,
    this.location,
    this.waitlistEnabled = false,
    this.maxWaitlist,
    this.bookingOpensHours = 168,
    this.bookingClosesMinutes = 60,
    this.cancellationDeadlineHours = 2,
  });

  final String name;
  final String? description;
  final String? classType;
  final DateTime startTime;
  final DateTime endTime;
  final int maxCapacity;
  final bool waitlistEnabled;
  final int? maxWaitlist;
  final String? instructorId;
  final String? instructorName;
  final String? location;
  final int bookingOpensHours;
  final int bookingClosesMinutes;
  final int cancellationDeadlineHours;

  /// Create from a template with specific date and time
  factory CreateClassDto.fromTemplate(
    ClassTemplate template, {
    required DateTime date,
    String? overrideInstructorId,
    String? overrideInstructorName,
    int? overrideCapacity,
    String? overrideLocation,
  }) {
    // Parse template times
    final startParts = template.startTime.split(':');
    final endParts = template.endTime.split(':');

    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final endTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    return CreateClassDto(
      name: template.name,
      description: template.description,
      classType: template.classType,
      startTime: startTime,
      endTime: endTime,
      maxCapacity: overrideCapacity ?? template.maxCapacity,
      waitlistEnabled: template.waitlistEnabled,
      maxWaitlist: template.maxWaitlist,
      instructorId: overrideInstructorId ?? template.instructorId,
      instructorName: overrideInstructorName ?? template.instructorName,
      location: overrideLocation ?? template.location,
      bookingOpensHours: template.bookingOpensHours,
      bookingClosesMinutes: template.bookingClosesMinutes,
      cancellationDeadlineHours: template.cancellationDeadlineHours,
    );
  }

  Map<String, dynamic> toJson(String organizationId) {
    return {
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'class_type': classType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'max_capacity': maxCapacity,
      'waitlist_enabled': waitlistEnabled,
      'max_waitlist': maxWaitlist,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'location': location,
      'booking_opens_hours': bookingOpensHours,
      'booking_closes_minutes': bookingClosesMinutes,
      'cancellation_deadline_hours': cancellationDeadlineHours,
      'is_cancelled': false,
    };
  }
}

/// DTO for updating a template
class UpdateTemplateDto {
  const UpdateTemplateDto({
    this.name,
    this.description,
    this.classType,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.maxCapacity,
    this.waitlistEnabled,
    this.maxWaitlist,
    this.instructorId,
    this.instructorName,
    this.location,
    this.bookingOpensHours,
    this.bookingClosesMinutes,
    this.cancellationDeadlineHours,
    this.isActive,
  });

  final String? name;
  final String? description;
  final String? classType;
  final int? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final int? maxCapacity;
  final bool? waitlistEnabled;
  final int? maxWaitlist;
  final String? instructorId;
  final String? instructorName;
  final String? location;
  final int? bookingOpensHours;
  final int? bookingClosesMinutes;
  final int? cancellationDeadlineHours;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (classType != null) map['class_type'] = classType;
    if (dayOfWeek != null) map['day_of_week'] = dayOfWeek;
    if (startTime != null) map['start_time'] = startTime;
    if (endTime != null) map['end_time'] = endTime;
    if (maxCapacity != null) map['max_capacity'] = maxCapacity;
    if (waitlistEnabled != null) map['waitlist_enabled'] = waitlistEnabled;
    if (maxWaitlist != null) map['max_waitlist'] = maxWaitlist;
    if (instructorId != null) map['instructor_id'] = instructorId;
    if (instructorName != null) map['instructor_name'] = instructorName;
    if (location != null) map['location'] = location;
    if (bookingOpensHours != null) {
      map['booking_opens_hours'] = bookingOpensHours;
    }
    if (bookingClosesMinutes != null) {
      map['booking_closes_minutes'] = bookingClosesMinutes;
    }
    if (cancellationDeadlineHours != null) {
      map['cancellation_deadline_hours'] = cancellationDeadlineHours;
    }
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}

/// DTO for creating a new template
class CreateTemplateDto {
  const CreateTemplateDto({
    required this.name,
    this.description,
    this.classType,
    this.dayOfWeek = 1,
    this.startTime = '09:00',
    this.endTime = '10:00',
    this.maxCapacity = 20,
    this.waitlistEnabled = true,
    this.maxWaitlist = 5,
    this.instructorId,
    this.instructorName,
    this.location,
    this.bookingOpensHours = 168,
    this.bookingClosesMinutes = 60,
    this.cancellationDeadlineHours = 2,
    this.isActive = true,
  });

  final String name;
  final String? description;
  final String? classType;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int maxCapacity;
  final bool waitlistEnabled;
  final int maxWaitlist;
  final String? instructorId;
  final String? instructorName;
  final String? location;
  final int bookingOpensHours;
  final int bookingClosesMinutes;
  final int cancellationDeadlineHours;
  final bool isActive;

  /// Creates a default template with sensible defaults (matching web)
  factory CreateTemplateDto.defaults() {
    return const CreateTemplateDto(
      name: '',
      dayOfWeek: 1,
      startTime: '09:00',
      endTime: '10:00',
      maxCapacity: 20,
      waitlistEnabled: true,
      maxWaitlist: 5,
      bookingOpensHours: 168,
      bookingClosesMinutes: 60,
      cancellationDeadlineHours: 2,
      isActive: true,
    );
  }

  Map<String, dynamic> toJson(String organizationId) {
    return {
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'class_type': classType,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'max_capacity': maxCapacity,
      'waitlist_enabled': waitlistEnabled,
      'max_waitlist': maxWaitlist,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'location': location,
      'booking_opens_hours': bookingOpensHours,
      'booking_closes_minutes': bookingClosesMinutes,
      'cancellation_deadline_hours': cancellationDeadlineHours,
      'is_active': isActive,
    };
  }

  CreateTemplateDto copyWith({
    String? name,
    String? description,
    String? classType,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    bool? waitlistEnabled,
    int? maxWaitlist,
    String? instructorId,
    String? instructorName,
    String? location,
    int? bookingOpensHours,
    int? bookingClosesMinutes,
    int? cancellationDeadlineHours,
    bool? isActive,
  }) {
    return CreateTemplateDto(
      name: name ?? this.name,
      description: description ?? this.description,
      classType: classType ?? this.classType,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      waitlistEnabled: waitlistEnabled ?? this.waitlistEnabled,
      maxWaitlist: maxWaitlist ?? this.maxWaitlist,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      location: location ?? this.location,
      bookingOpensHours: bookingOpensHours ?? this.bookingOpensHours,
      bookingClosesMinutes: bookingClosesMinutes ?? this.bookingClosesMinutes,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Instructor model for picker
class Instructor {
  const Instructor({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.role,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? role;

  /// Display name (full name or email)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  /// Get initials for avatar
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, 1).toUpperCase();
    }
    return email.substring(0, 1).toUpperCase();
  }

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
    );
  }
}
