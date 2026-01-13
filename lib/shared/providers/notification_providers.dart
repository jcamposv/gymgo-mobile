import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/push_token_repository.dart';
import '../../features/classes/presentation/providers/classes_providers.dart';
import '../../features/notifications/presentation/providers/inbox_providers.dart';

/// Provider for PushTokenRepository
final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(Supabase.instance.client);
});

/// Provider for notification permission status
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  return NotificationService.instance.requestPermissions();
});

/// Provider to track if notifications are initialized
final notificationsInitializedProvider = StateProvider<bool>((ref) => false);

/// Provider for the current FCM token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  return NotificationService.instance.getToken();
});

/// Provider for foreground notification messages
/// Use this to show in-app alerts when notifications arrive
final foregroundNotificationProvider = StateProvider<RemoteMessage?>((ref) => null);

/// Notifier for handling notification-related actions
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this._ref, this._tokenRepository)
      : super(const NotificationState());

  final Ref _ref;
  final PushTokenRepository _tokenRepository;

  /// Initialize notifications for the current user
  Future<void> initialize() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true);

    try {
      // Initialize notification service (if not already done in main)
      await NotificationService.instance.initialize();

      // Initialize token repository (sync token to backend)
      await _tokenRepository.initialize();

      // Set up foreground notification callback
      NotificationService.instance.setOnForegroundNotification(_handleForegroundNotification);

      // Initialize notifications inbox
      await _ref.read(inboxProvider.notifier).initialize();

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        hasPermission: true,
      );
    } catch (e) {
      debugPrint('NotificationNotifier: Initialization error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Handle foreground notification
  void _handleForegroundNotification(RemoteMessage message) {
    debugPrint('NotificationNotifier: Foreground notification received');

    // Update foreground notification provider for UI
    _ref.read(foregroundNotificationProvider.notifier).state = message;

    // Save notification to inbox
    _ref.read(inboxProvider.notifier).addFromRemoteMessage(message);

    // Refresh classes if it's a class-related notification
    final type = message.data['type'] as String?;
    if (_isClassRelatedNotification(type)) {
      _ref.invalidate(classesProvider);
      _ref.invalidate(nextUserClassProvider);
    }
  }

  /// Check if notification type is class-related
  bool _isClassRelatedNotification(String? type) {
    return type == 'class_created' ||
        type == 'class_updated' ||
        type == 'class_cancelled' ||
        type == 'booking_confirmed' ||
        type == 'booking_cancelled';
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    final granted = await NotificationService.instance.requestPermissions();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  /// Sync token to backend (retry if needed)
  Future<void> syncToken() async {
    final token = await NotificationService.instance.getToken();
    if (token != null) {
      await _tokenRepository.syncTokenToBackend(token);
    }
  }

  /// Handle user logout - deactivate push token
  Future<void> onLogout() async {
    await _tokenRepository.deactivateToken();
    state = const NotificationState();
  }

  /// Clear the current foreground notification (after displaying)
  void clearForegroundNotification() {
    _ref.read(foregroundNotificationProvider.notifier).state = null;
  }
}

/// Provider for NotificationNotifier
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final tokenRepository = ref.watch(pushTokenRepositoryProvider);
  return NotificationNotifier(ref, tokenRepository);
});

/// State class for notifications
class NotificationState {
  const NotificationState({
    this.isInitialized = false,
    this.isLoading = false,
    this.hasPermission = false,
    this.error,
  });

  final bool isInitialized;
  final bool isLoading;
  final bool hasPermission;
  final String? error;

  NotificationState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? hasPermission,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      error: error,
    );
  }
}

/// Extension for easy access to notification state
extension NotificationStateX on NotificationState {
  bool get hasError => error != null;
}
