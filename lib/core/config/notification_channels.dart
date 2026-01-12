import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channel configurations
class NotificationChannels {
  NotificationChannels._();

  /// Channel for class-related notifications (new classes, reminders, cancellations)
  static const AndroidNotificationChannel classes = AndroidNotificationChannel(
    'classes',
    'Classes',
    description: 'Notifications about new classes, reminders, and updates',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  /// Channel for booking confirmations and updates
  static const AndroidNotificationChannel bookings = AndroidNotificationChannel(
    'bookings',
    'Bookings',
    description: 'Notifications about your class reservations',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
    showBadge: true,
  );

  /// Channel for general gym announcements
  static const AndroidNotificationChannel announcements = AndroidNotificationChannel(
    'announcements',
    'Announcements',
    description: 'General gym announcements and news',
    importance: Importance.defaultImportance,
    enableVibration: false,
    playSound: true,
    showBadge: true,
  );

  /// Get all channels for registration
  static List<AndroidNotificationChannel> get all => [
    classes,
    bookings,
    announcements,
  ];

  /// Get channel by notification type
  static AndroidNotificationChannel getChannelForType(String type) {
    switch (type) {
      case 'class_created':
      case 'class_updated':
      case 'class_cancelled':
      case 'class_reminder':
        return classes;
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_waitlist':
        return bookings;
      case 'announcement':
      case 'promotion':
      default:
        return announcements;
    }
  }
}

/// Notification type constants (matches backend payload 'type' field)
class NotificationTypes {
  NotificationTypes._();

  static const String classCreated = 'class_created';
  static const String classUpdated = 'class_updated';
  static const String classCancelled = 'class_cancelled';
  static const String classReminder = 'class_reminder';
  static const String bookingConfirmed = 'booking_confirmed';
  static const String bookingCancelled = 'booking_cancelled';
  static const String announcement = 'announcement';
}
