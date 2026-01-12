import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Repository for managing FCM push tokens
///
/// Responsibilities:
/// - Get and store FCM token
/// - Send token to backend (Supabase)
/// - Handle token refresh
/// - Subscribe to gym topics for broadcast notifications
///
/// Backend Assumptions:
/// - Table `push_tokens` exists with columns:
///   - id (uuid, primary key)
///   - user_id (uuid, foreign key to auth.users)
///   - organization_id (uuid, foreign key to organizations/gyms)
///   - token (text, the FCM token)
///   - platform (text, 'ios' or 'android')
///   - device_id (text, optional unique device identifier)
///   - app_version (text, app version string)
///   - created_at (timestamp)
///   - updated_at (timestamp)
///   - is_active (boolean, default true)
///
/// - Alternatively, tokens can be stored in `members` table as `push_token` column
/// - Backend should have RLS policies to allow users to manage their own tokens
///
/// Topic-based approach (recommended for gym broadcasts):
/// - Subscribe device to topic `gym_<organizationId>`
/// - Backend sends to topic when new class is created
/// - No need to iterate through individual tokens
class PushTokenRepository {
  PushTokenRepository(this._client);

  final SupabaseClient _client;

  static const String _tokenKey = 'fcm_push_token';
  static const String _tokenSyncedKey = 'fcm_token_synced';
  static const String _lastGymIdKey = 'fcm_last_gym_id';

  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Initialize token management
  /// Call this after user logs in
  Future<void> initialize() async {
    // Get current token
    final token = await NotificationService.instance.getToken();
    if (token != null) {
      await _saveTokenLocally(token);
      await syncTokenToBackend(token);
    }

    // Listen for token refreshes
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = NotificationService.instance.onTokenRefresh.listen((newToken) {
      debugPrint('PushTokenRepository: Token refreshed');
      _handleTokenRefresh(newToken);
    });
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    final oldToken = await _getLocalToken();
    if (oldToken != newToken) {
      await _saveTokenLocally(newToken);
      await syncTokenToBackend(newToken);
    }
  }

  /// Sync token to backend
  /// Uses upsert to handle both new and existing tokens
  Future<bool> syncTokenToBackend(String token) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('PushTokenRepository: No user logged in, skipping sync');
        return false;
      }

      // Get member's organization ID
      final memberResponse = await _client
          .from('members')
          .select('organization_id')
          .eq('user_id', userId)
          .maybeSingle();

      final organizationId = memberResponse?['organization_id'] as String?;
      if (organizationId == null) {
        debugPrint('PushTokenRepository: No organization found for user');
        return false;
      }

      // Subscribe to gym topic for broadcasts (this is the key part for topic-based notifications)
      await _subscribeToGymTopic(organizationId);

      // Optional: Store token in database (skip if table doesn't exist)
      try {
        await _syncToTokensTable(userId, organizationId, token);
      } catch (e) {
        debugPrint('PushTokenRepository: Token table sync failed (non-critical): $e');
        // Continue - topic subscription is more important for broadcasts
      }

      // Mark as synced
      await _markTokenSynced(true);
      debugPrint('PushTokenRepository: Token synced successfully');
      return true;
    } catch (e) {
      debugPrint('PushTokenRepository: Error syncing token: $e');
      await _markTokenSynced(false);
      // Schedule retry
      _scheduleRetry(token);
      return false;
    }
  }

  /// Sync token to dedicated push_tokens table
  Future<void> _syncToTokensTable(String userId, String organizationId, String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final appVersion = '1.0.0'; // TODO: Get from package_info_plus

    // Upsert token (insert or update if exists)
    // Using user_id + platform as unique constraint
    await _client.from('push_tokens').upsert(
      {
        'user_id': userId,
        'organization_id': organizationId,
        'token': token,
        'platform': platform,
        'app_version': appVersion,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id, platform',
    );
  }

  /// Alternative: Sync token to members table
  Future<void> _syncToMembersTable(String userId, String token) async {
    await _client
        .from('members')
        .update({'push_token': token})
        .eq('user_id', userId);
  }

  /// Subscribe to gym topic for broadcast notifications
  Future<void> _subscribeToGymTopic(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastGymId = prefs.getString(_lastGymIdKey);

    // Unsubscribe from old gym if changed
    if (lastGymId != null && lastGymId != organizationId) {
      await NotificationService.instance.unsubscribeFromTopic('gym_$lastGymId');
    }

    // Subscribe to new gym topic
    await NotificationService.instance.subscribeToTopic('gym_$organizationId');
    await prefs.setString(_lastGymIdKey, organizationId);

    debugPrint('PushTokenRepository: Subscribed to gym_$organizationId');
  }

  /// Unsubscribe from all topics (on logout)
  Future<void> unsubscribeFromAllTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGymId = prefs.getString(_lastGymIdKey);

    if (lastGymId != null) {
      await NotificationService.instance.unsubscribeFromTopic('gym_$lastGymId');
      await prefs.remove(_lastGymIdKey);
    }
  }

  /// Deactivate token on backend (on logout)
  Future<void> deactivateToken() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final platform = Platform.isIOS ? 'ios' : 'android';

      // Mark token as inactive
      await _client
          .from('push_tokens')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('platform', platform);

      // Unsubscribe from topics
      await unsubscribeFromAllTopics();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenSyncedKey);

      // Cancel token refresh listener
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      debugPrint('PushTokenRepository: Token deactivated');
    } catch (e) {
      debugPrint('PushTokenRepository: Error deactivating token: $e');
    }
  }

  /// Delete token completely (optional, more aggressive than deactivate)
  Future<void> deleteToken() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final platform = Platform.isIOS ? 'ios' : 'android';

      // Delete from backend
      await _client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('platform', platform);

      // Delete FCM token
      await NotificationService.instance.deleteToken();

      // Clear local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenSyncedKey);
      await prefs.remove(_lastGymIdKey);

      debugPrint('PushTokenRepository: Token deleted');
    } catch (e) {
      debugPrint('PushTokenRepository: Error deleting token: $e');
    }
  }

  /// Check if token needs sync
  Future<bool> needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tokenSyncedKey) != true;
  }

  /// Schedule retry for failed sync with exponential backoff
  void _scheduleRetry(String token, {int attempt = 1}) {
    if (attempt > 5) {
      debugPrint('PushTokenRepository: Max retry attempts reached');
      return;
    }

    final delay = Duration(seconds: (2 << attempt)); // 4, 8, 16, 32, 64 seconds
    debugPrint('PushTokenRepository: Scheduling retry in ${delay.inSeconds}s (attempt $attempt)');

    Future.delayed(delay, () async {
      final success = await syncTokenToBackend(token);
      if (!success) {
        _scheduleRetry(token, attempt: attempt + 1);
      }
    });
  }

  // Local storage helpers

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> _getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _markTokenSynced(bool synced) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tokenSyncedKey, synced);
  }

  /// Dispose resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
