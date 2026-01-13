import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_notification.dart';

/// Abstract repository interface for notifications
/// Allows swapping between local storage and backend API
abstract class NotificationsRepository {
  /// Fetch all notifications (paginated)
  Future<List<AppNotification>> fetch({int page = 1, int pageSize = 50});

  /// Save a new notification
  Future<void> save(AppNotification notification);

  /// Get unread notification count
  Future<int> unreadCount();

  /// Mark a notification as read
  Future<void> markRead(String id);

  /// Mark all notifications as read
  Future<void> markAllRead();

  /// Delete a notification
  Future<void> delete(String id);

  /// Clear all notifications
  Future<void> clearAll();

  /// Stream of unread count updates
  Stream<int> get unreadCountStream;
}

/// Local storage implementation using SharedPreferences
/// For MVP - stores notifications locally on device
class LocalNotificationsRepository implements NotificationsRepository {
  LocalNotificationsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _storageKey = 'app_notifications';
  static const _maxNotifications = 100; // Limit stored notifications

  // Stream controller for unread count updates
  final _unreadCountController = ValueNotifier<int>(0);

  @override
  Stream<int> get unreadCountStream => _unreadCountController.toStream();

  /// Initialize and load initial unread count
  Future<void> initialize() async {
    final count = await unreadCount();
    _unreadCountController.value = count;
  }

  @override
  Future<List<AppNotification>> fetch({int page = 1, int pageSize = 50}) async {
    try {
      final notifications = await _loadNotifications();

      // Sort by newest first
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply pagination
      final start = (page - 1) * pageSize;
      if (start >= notifications.length) return [];

      final end = start + pageSize;
      return notifications.sublist(
        start,
        end > notifications.length ? notifications.length : end,
      );
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error fetching: $e');
      return [];
    }
  }

  @override
  Future<void> save(AppNotification notification) async {
    try {
      final notifications = await _loadNotifications();

      // Check if notification already exists (by ID)
      final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex >= 0) {
        // Update existing
        notifications[existingIndex] = notification;
      } else {
        // Add new
        notifications.insert(0, notification);
      }

      // Trim to max notifications
      if (notifications.length > _maxNotifications) {
        notifications.removeRange(_maxNotifications, notifications.length);
      }

      await _saveNotifications(notifications);
      await _updateUnreadCount();

      debugPrint('LocalNotificationsRepository: Saved notification ${notification.id}');
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error saving: $e');
      rethrow;
    }
  }

  @override
  Future<int> unreadCount() async {
    try {
      final notifications = await _loadNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error getting unread count: $e');
      return 0;
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      final notifications = await _loadNotifications();
      final index = notifications.indexWhere((n) => n.id == id);

      if (index >= 0) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveNotifications(notifications);
        await _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error marking read: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      final notifications = await _loadNotifications();
      final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
      await _saveNotifications(updated);
      await _updateUnreadCount();
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error marking all read: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final notifications = await _loadNotifications();
      notifications.removeWhere((n) => n.id == id);
      await _saveNotifications(notifications);
      await _updateUnreadCount();
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error deleting: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _prefs.remove(_storageKey);
      await _updateUnreadCount();
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error clearing: $e');
      rethrow;
    }
  }

  /// Load notifications from SharedPreferences
  Future<List<AppNotification>> _loadNotifications() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('LocalNotificationsRepository: Error parsing: $e');
      return [];
    }
  }

  /// Save notifications to SharedPreferences
  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Update the unread count notifier
  Future<void> _updateUnreadCount() async {
    final count = await unreadCount();
    _unreadCountController.value = count;
  }
}

/// Extension to convert ValueNotifier to Stream
extension ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() async* {
    yield value;
    while (true) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield value;
    }
  }
}
