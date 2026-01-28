/// Status of a gym class
enum ClassStatus {
  available,
  full,
  finished,
}

/// Represents a participant in a class
class ClassParticipant {
  const ClassParticipant({
    required this.memberId,
    required this.name,
    this.avatarUrl,
  });

  final String memberId;
  final String name;
  final String? avatarUrl;

  factory ClassParticipant.fromJson(Map<String, dynamic> json) {
    return ClassParticipant(
      memberId: json['member_id'] as String,
      name: json['full_name'] as String? ?? 'Miembro',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Represents a gym class/session
class GymClass {
  const GymClass({
    required this.id,
    required this.name,
    required this.instructorId,
    required this.instructorName,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    required this.currentParticipants,
    this.participantAvatars = const [],
    this.participants = const [],
    this.isUserBooked = false,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String instructorId;
  final String instructorName;
  final String location;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int maxCapacity;
  final int currentParticipants;
  final List<String> participantAvatars;
  final List<ClassParticipant> participants;
  final bool isUserBooked;
  final String? description;
  final String? imageUrl;

  /// Get the status of the class based on capacity and time
  ClassStatus get status {
    final now = DateTime.now();
    final classDateTime = _getClassEndDateTime();

    if (classDateTime.isBefore(now)) {
      return ClassStatus.finished;
    }

    if (currentParticipants >= maxCapacity) {
      return ClassStatus.full;
    }

    return ClassStatus.available;
  }

  DateTime _getClassEndDateTime() {
    final timeParts = endTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Check if the class starts within a time range (in hours)
  bool get startsWithinHour {
    final now = DateTime.now();
    final timeParts = startTime.split(':');
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final difference = startDateTime.difference(now);
    return difference.inMinutes > 0 && difference.inMinutes <= 60;
  }

  /// Get the hour of the class for filtering
  int get startHour {
    return int.parse(startTime.split(':')[0]);
  }

  /// Create a copy with updated fields
  GymClass copyWith({
    String? id,
    String? name,
    String? instructorId,
    String? instructorName,
    String? location,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? maxCapacity,
    int? currentParticipants,
    List<String>? participantAvatars,
    List<ClassParticipant>? participants,
    bool? isUserBooked,
    String? description,
    String? imageUrl,
  }) {
    return GymClass(
      id: id ?? this.id,
      name: name ?? this.name,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      participants: participants ?? this.participants,
      isUserBooked: isUserBooked ?? this.isUserBooked,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Create from JSON (Supabase)
  factory GymClass.fromJson(
    Map<String, dynamic> json, {
    bool isUserBooked = false,
    List<String>? participantAvatars,
    List<ClassParticipant>? participants,
  }) {
    return GymClass(
      id: json['id'] as String,
      name: json['name'] as String,
      instructorId: json['instructor_id'] as String,
      instructorName: json['instructor_name'] as String? ?? 'Instructor',
      location: json['location'] as String? ?? 'Sala principal',
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      maxCapacity: json['max_capacity'] as int? ?? 20,
      currentParticipants: json['current_participants'] as int? ?? 0,
      participantAvatars: participantAvatars ?? const [],
      participants: participants ?? const [],
      isUserBooked: isUserBooked,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'location': location,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'max_capacity': maxCapacity,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

/// Booking status enum matching Supabase schema
enum BookingStatus {
  confirmed,
  cancelled,
  attended,
  noShow,
  waitlist,
}

/// Represents a class booking (reservation)
class ClassReservation {
  const ClassReservation({
    required this.id,
    required this.classId,
    required this.memberId,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    this.checkedInAt,
    this.waitlistPosition,
  });

  final String id;
  final String classId;
  final String memberId;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final DateTime? checkedInAt;
  final int? waitlistPosition;

  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isOnWaitlist => status == BookingStatus.waitlist;

  factory ClassReservation.fromJson(Map<String, dynamic> json) {
    return ClassReservation(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      memberId: json['member_id'] as String,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      waitlistPosition: json['waitlist_position'] as int?,
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'attended':
        return BookingStatus.attended;
      case 'no_show':
        return BookingStatus.noShow;
      case 'waitlist':
        return BookingStatus.waitlist;
      default:
        return BookingStatus.confirmed;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'member_id': memberId,
      'status': status.name,
    };
  }
}
