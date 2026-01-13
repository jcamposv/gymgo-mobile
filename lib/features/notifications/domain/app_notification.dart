import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notification types supported by the app
class NotificationType {
  NotificationType._();

  static const String classCreated = 'class_created';
  static const String classUpdated = 'class_updated';
  static const String classCancelled = 'class_cancelled';
  static const String bookingConfirmed = 'booking_confirmed';
  static const String bookingCancelled = 'booking_cancelled';
  static const String routineUpdated = 'routine_updated';
  static const String routineAssigned = 'routine_assigned';
  static const String measurementReminder = 'measurement_reminder';
  static const String general = 'general';

  static List<String> get all => [
        classCreated,
        classUpdated,
        classCancelled,
        bookingConfirmed,
        bookingCancelled,
        routineUpdated,
        routineAssigned,
        measurementReminder,
        general,
      ];
}

/// In-app notification model for the notifications inbox
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> data;

  /// Create from FCM RemoteMessage
  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    return AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: data['type'] as String? ?? NotificationType.general,
      title: notification?.title ?? data['title'] as String? ?? 'GymGo',
      body: notification?.body ?? data['body'] as String? ?? '',
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
      data: Map<String, dynamic>.from(data),
    );
  }

  /// Create from JSON (for local storage)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? NotificationType.general,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] != null
          ? Map<String, dynamic>.from(
              json['data'] is String
                  ? jsonDecode(json['data'] as String) as Map<String, dynamic>
                  : json['data'] as Map<String, dynamic>,
            )
          : {},
    );
  }

  /// Convert to JSON (for local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  /// Create a copy with updated fields
  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  /// Get class ID from data payload (if applicable)
  String? get classId => data['classId'] as String?;

  /// Get routine ID from data payload (if applicable)
  String? get routineId => data['routineId'] as String?;

  /// Get scheduled date from data payload (if applicable)
  String? get scheduledDate => data['scheduledDate'] as String?;

  /// Check if this notification relates to classes
  bool get isClassRelated =>
      type == NotificationType.classCreated ||
      type == NotificationType.classUpdated ||
      type == NotificationType.classCancelled ||
      type == NotificationType.bookingConfirmed ||
      type == NotificationType.bookingCancelled;

  /// Check if this notification relates to routines
  bool get isRoutineRelated =>
      type == NotificationType.routineUpdated ||
      type == NotificationType.routineAssigned;

  @override
  List<Object?> get props => [id, type, title, body, createdAt, isRead, data];
}

/// Extension for formatting notification timestamps
extension AppNotificationTimeFormat on AppNotification {
  /// Get human-readable time string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';

    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]}';
  }
}
