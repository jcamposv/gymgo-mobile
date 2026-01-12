import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/classes/presentation/providers/classes_providers.dart';
import '../config/notification_channels.dart';
import '../router/routes.dart';

/// NotificationRouter handles navigation based on notification payload
///
/// Central handler for notification tap actions, routing to appropriate screens
/// based on the notification type and data.
class NotificationRouter {
  NotificationRouter._();

  /// Handle notification tap and navigate to appropriate screen
  ///
  /// [data] - The notification payload data map
  /// [navigatorKey] - Global navigator key for navigation
  /// [ref] - Riverpod ref for provider access (optional)
  static void handleNotificationTap(
    Map<String, String> data, {
    GlobalKey<NavigatorState>? navigatorKey,
    WidgetRef? ref,
  }) {
    final type = data['type'];
    debugPrint('NotificationRouter: Handling tap for type: $type');
    debugPrint('NotificationRouter: Data: $data');

    if (navigatorKey?.currentContext == null) {
      debugPrint('NotificationRouter: No context available, deferring navigation');
      return;
    }

    final context = navigatorKey!.currentContext!;

    switch (type) {
      case NotificationTypes.classCreated:
        _handleClassCreated(context, data, ref);
        break;

      case NotificationTypes.classUpdated:
        _handleClassUpdated(context, data, ref);
        break;

      case NotificationTypes.classCancelled:
        _handleClassCancelled(context, data, ref);
        break;

      case NotificationTypes.classReminder:
        _handleClassReminder(context, data, ref);
        break;

      case NotificationTypes.bookingConfirmed:
      case NotificationTypes.bookingCancelled:
        _handleBookingNotification(context, data, ref);
        break;

      case NotificationTypes.announcement:
      default:
        // Default: just go to home
        _navigateToHome(context);
        break;
    }
  }

  /// Handle class_created notification
  /// Navigate to classes screen with the class date selected
  static void _handleClassCreated(
    BuildContext context,
    Map<String, String> data,
    WidgetRef? ref,
  ) {
    debugPrint('NotificationRouter: Navigating for class_created');

    // Parse the class start time to select that date
    final startTimeStr = data['startTime'];
    if (startTimeStr != null && ref != null) {
      try {
        final startTime = DateTime.parse(startTimeStr);
        // Update selected date provider
        ref.read(selectedDateProvider.notifier).state = startTime;
      } catch (e) {
        debugPrint('NotificationRouter: Error parsing startTime: $e');
      }
    }

    // Invalidate classes provider to refresh the list
    ref?.invalidate(classesProvider);

    // Navigate to classes screen
    context.go(Routes.memberClasses);
  }

  /// Handle class_updated notification
  static void _handleClassUpdated(
    BuildContext context,
    Map<String, String> data,
    WidgetRef? ref,
  ) {
    debugPrint('NotificationRouter: Navigating for class_updated');

    // Parse date and navigate
    final startTimeStr = data['startTime'];
    if (startTimeStr != null && ref != null) {
      try {
        final startTime = DateTime.parse(startTimeStr);
        ref.read(selectedDateProvider.notifier).state = startTime;
      } catch (e) {
        debugPrint('NotificationRouter: Error parsing startTime: $e');
      }
    }

    ref?.invalidate(classesProvider);
    context.go(Routes.memberClasses);
  }

  /// Handle class_cancelled notification
  static void _handleClassCancelled(
    BuildContext context,
    Map<String, String> data,
    WidgetRef? ref,
  ) {
    debugPrint('NotificationRouter: Navigating for class_cancelled');

    // Refresh classes to remove cancelled class
    ref?.invalidate(classesProvider);

    // Navigate to classes screen
    context.go(Routes.memberClasses);
  }

  /// Handle class_reminder notification
  static void _handleClassReminder(
    BuildContext context,
    Map<String, String> data,
    WidgetRef? ref,
  ) {
    debugPrint('NotificationRouter: Navigating for class_reminder');

    // Navigate to classes screen with today's date
    ref?.read(selectedDateProvider.notifier).state = DateTime.now();
    ref?.invalidate(classesProvider);

    context.go(Routes.memberClasses);
  }

  /// Handle booking-related notifications
  static void _handleBookingNotification(
    BuildContext context,
    Map<String, String> data,
    WidgetRef? ref,
  ) {
    debugPrint('NotificationRouter: Navigating for booking notification');

    // Refresh classes
    ref?.invalidate(classesProvider);

    // Navigate to classes screen
    context.go(Routes.memberClasses);
  }

  /// Navigate to home screen (default action)
  static void _navigateToHome(BuildContext context) {
    debugPrint('NotificationRouter: Navigating to home');
    context.go(Routes.home);
  }

  /// Navigate to a specific class detail (if route exists)
  /// Currently navigates to classes list; can be extended for detail view
  static void navigateToClass(
    BuildContext context,
    String classId,
    DateTime? classDate,
    WidgetRef? ref,
  ) {
    if (classDate != null) {
      ref?.read(selectedDateProvider.notifier).state = classDate;
    }
    ref?.invalidate(classesProvider);
    context.go(Routes.memberClasses);
  }
}

/// Extension to easily handle notifications from anywhere
extension NotificationHandlerExtension on BuildContext {
  /// Handle notification data and navigate accordingly
  void handleNotificationData(Map<String, String> data, {WidgetRef? ref}) {
    final type = data['type'];

    switch (type) {
      case NotificationTypes.classCreated:
      case NotificationTypes.classUpdated:
      case NotificationTypes.classCancelled:
      case NotificationTypes.classReminder:
      case NotificationTypes.bookingConfirmed:
      case NotificationTypes.bookingCancelled:
        // Parse date if available
        final startTimeStr = data['startTime'];
        if (startTimeStr != null && ref != null) {
          try {
            final startTime = DateTime.parse(startTimeStr);
            ref.read(selectedDateProvider.notifier).state = startTime;
          } catch (_) {}
        }
        ref?.invalidate(classesProvider);
        go(Routes.memberClasses);
        break;

      default:
        go(Routes.home);
    }
  }
}
