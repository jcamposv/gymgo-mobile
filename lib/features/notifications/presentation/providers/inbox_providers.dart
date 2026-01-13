import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

/// Provider for the notifications repository
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalNotificationsRepository(prefs);
});

/// Provider for unread notifications count
final unreadNotificationsCountProvider = StateProvider<int>((ref) => 0);

/// Provider for the list of notifications
final notificationsListProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.fetch();
});

/// State for the notifications inbox
class InboxState {
  const InboxState({
    this.notifications = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.unreadCount = 0,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final int unreadCount;

  InboxState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    int? unreadCount,
  }) {
    return InboxState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => notifications.isEmpty && !isLoading && !hasError;
}

/// Controller for the notifications inbox
class InboxNotifier extends StateNotifier<InboxState> {
  InboxNotifier(this._repository) : super(const InboxState());

  final NotificationsRepository _repository;

  /// Initialize the inbox
  Future<void> initialize() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final notifications = await _repository.fetch();
      final unreadCount = await _repository.unreadCount();

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('InboxNotifier: Error initializing: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar notificaciones',
      );
    }
  }

  /// Refresh the notifications list
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final notifications = await _repository.fetch();
      final unreadCount = await _repository.unreadCount();

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isRefreshing: false,
      );
    } catch (e) {
      debugPrint('InboxNotifier: Error refreshing: $e');
      state = state.copyWith(
        isRefreshing: false,
        error: 'Error al actualizar',
      );
    }
  }

  /// Add a new notification from FCM
  Future<void> addFromRemoteMessage(RemoteMessage message) async {
    try {
      final notification = AppNotification.fromRemoteMessage(message);
      await _repository.save(notification);

      // Update state
      final notifications = await _repository.fetch();
      final unreadCount = await _repository.unreadCount();

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      );

      debugPrint('InboxNotifier: Added notification from FCM: ${notification.id}');
    } catch (e) {
      debugPrint('InboxNotifier: Error adding from FCM: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _repository.markRead(id);

      // Update local state
      final updated = state.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();

      final unreadCount = await _repository.unreadCount();

      state = state.copyWith(
        notifications: updated,
        unreadCount: unreadCount,
      );
    } catch (e) {
      debugPrint('InboxNotifier: Error marking as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllRead();

      // Update local state
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: 0,
      );
    } catch (e) {
      debugPrint('InboxNotifier: Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);

      // Update local state
      final updated = state.notifications.where((n) => n.id != id).toList();
      final unreadCount = await _repository.unreadCount();

      state = state.copyWith(
        notifications: updated,
        unreadCount: unreadCount,
      );
    } catch (e) {
      debugPrint('InboxNotifier: Error deleting: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      await _repository.clearAll();

      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
      );
    } catch (e) {
      debugPrint('InboxNotifier: Error clearing: $e');
    }
  }

  /// Update unread count (called externally when notification arrives)
  Future<void> updateUnreadCount() async {
    final unreadCount = await _repository.unreadCount();
    state = state.copyWith(unreadCount: unreadCount);
  }
}

/// Provider for the inbox notifier
final inboxProvider = StateNotifierProvider<InboxNotifier, InboxState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return InboxNotifier(repository);
});

/// Provider for just the unread count (for badge display)
final unreadCountProvider = Provider<int>((ref) {
  final inbox = ref.watch(inboxProvider);
  return inbox.unreadCount;
});

/// Provider to check if there are unread notifications
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final count = ref.watch(unreadCountProvider);
  return count > 0;
});
