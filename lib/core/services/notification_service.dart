import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/notification_channels.dart';
import 'notification_router.dart';

/// Global key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Callback type for in-app notification handling
typedef OnNotificationReceived = void Function(RemoteMessage message);

/// Firebase background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');

  // FCM automatically shows the notification if 'notification' payload exists
  // If you need to customize, use flutter_local_notifications here
  // But typically, the system notification is already shown
}

/// NotificationService handles all push notification logic
///
/// Responsibilities:
/// - Initialize Firebase & FCM
/// - Request notification permissions
/// - Set up local notifications for foreground display
/// - Handle message states (foreground, background, killed)
/// - Trigger navigation on notification tap
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  WidgetRef? _ref;
  OnNotificationReceived? _onForegroundNotification;

  /// Set the Riverpod ref for provider access
  void setRef(WidgetRef ref) {
    _ref = ref;
  }

  /// Set callback for foreground notification UI handling
  void setOnForegroundNotification(OnNotificationReceived callback) {
    _onForegroundNotification = callback;
  }

  /// Initialize the notification service
  /// Call this in main() after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('NotificationService: Initializing...');

    // 1. Initialize Firebase (should already be done in main.dart)
    // await Firebase.initializeApp();

    // 2. Set up flutter_local_notifications
    await _initializeLocalNotifications();

    // 3. Request permissions
    await requestPermissions();

    // 4. Configure foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Set up message handlers
    _setupMessageHandlers();

    // 6. Handle notification that opened the app (app was killed)
    await _handleInitialMessage();

    _isInitialized = true;
    debugPrint('NotificationService: Initialization complete');
  }

  /// Initialize flutter_local_notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We request separately
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        for (final channel in NotificationChannels.all) {
          await androidPlugin.createNotificationChannel(channel);
        }
        debugPrint('NotificationService: Android channels created');
      }
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    debugPrint('NotificationService: Requesting permissions...');

    // Request FCM permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('NotificationService: Permission status: ${settings.authorizationStatus}');

    // On Android 13+, also request local notification permission
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final localGranted = await androidPlugin.requestNotificationsPermission();
        debugPrint('NotificationService: Local notification permission: $localGranted');
      }
    }

    return granted;
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handler 1: Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handler 2: Background message tap (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle initial message when app opened from killed state
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('NotificationService: App opened from killed state with message');
      // Delay navigation to allow app to fully initialize
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  /// Handle foreground message
  /// Shows local notification AND triggers in-app alert
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('NotificationService: Foreground message received');
    debugPrint('NotificationService: Data: ${message.data}');
    debugPrint('NotificationService: Notification: ${message.notification?.title}');

    // 1. Show local notification (system tray)
    await _showLocalNotification(message);

    // 2. Trigger in-app callback (for SnackBar/Dialog)
    _onForegroundNotification?.call(message);

    // 3. Refresh relevant data (e.g., classes list)
    _refreshDataForNotificationType(message.data['type']);
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Determine title and body
    final title = notification?.title ?? (data['title'] as String?) ?? 'GymGo';
    final body = notification?.body ?? (data['body'] as String?) ?? '';

    // Get appropriate channel
    final type = data['type'] as String? ?? '';
    final channel = NotificationChannels.getChannelForType(type);

    // Build notification details
    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Generate unique notification ID from message ID
    final notificationId = message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    // Store payload for tap handling
    final payload = _encodePayload(data);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap (from background or local notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('NotificationService: Notification tapped');
    debugPrint('NotificationService: Data: ${message.data}');

    NotificationRouter.handleNotificationTap(
      message.data.map((k, v) => MapEntry(k, v.toString())),
      navigatorKey: navigatorKey,
      ref: _ref,
    );
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('NotificationService: Local notification tapped');
    debugPrint('NotificationService: Payload: ${response.payload}');

    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      NotificationRouter.handleNotificationTap(
        data,
        navigatorKey: navigatorKey,
        ref: _ref,
      );
    }
  }

  /// Refresh data based on notification type
  void _refreshDataForNotificationType(String? type) {
    if (_ref == null) return;

    switch (type) {
      case NotificationTypes.classCreated:
      case NotificationTypes.classUpdated:
      case NotificationTypes.classCancelled:
        // Import and invalidate classes provider
        // Note: We can't directly import here to avoid circular deps
        // Instead, we'll use a callback or event system
        debugPrint('NotificationService: Should refresh classes');
        break;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('NotificationService: FCM Token: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      debugPrint('NotificationService: Error getting token: $e');
      return null;
    }
  }

  /// Listen to token refresh
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Subscribe to a topic (e.g., gym_<gymId>)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('NotificationService: Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('NotificationService: Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('NotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('NotificationService: Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (e.g., on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('NotificationService: Token deleted');
    } catch (e) {
      debugPrint('NotificationService: Error deleting token: $e');
    }
  }

  /// Encode data map to payload string
  String _encodePayload(Map<String, dynamic> data) {
    // Simple encoding: key1=value1&key2=value2
    return data.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  /// Decode payload string to data map
  Map<String, String> _decodePayload(String payload) {
    final data = <String, String>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        data[Uri.decodeComponent(parts[0])] = Uri.decodeComponent(parts[1]);
      }
    }
    return data;
  }
}

/// Background notification tap handler - MUST be top-level function
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  debugPrint('NotificationService: Background local notification tapped');
  // This is called when the app is in background
  // The actual navigation will be handled when the app comes to foreground
}
