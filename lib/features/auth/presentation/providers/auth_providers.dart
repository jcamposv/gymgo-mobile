import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../shared/providers/notification_providers.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_exception.dart';
import '../../domain/auth_state.dart' as app;

/// Provider for the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Main auth state notifier
class AuthNotifier extends StateNotifier<app.AuthState> {
  AuthNotifier(this._repository, this._ref) : super(const app.AuthInitial()) {
    _initialize();
  }

  final AuthRepository _repository;
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  void _initialize() {
    // Check if already authenticated
    if (_repository.isAuthenticated) {
      final session = _repository.currentSession!;
      final user = _repository.currentUser!;
      state = app.Authenticated(user: user, session: session);
    } else {
      state = const app.Unauthenticated();
    }

    // Listen to auth state changes
    _authSubscription = _repository.authStateChanges.listen((event) {
      if (event.session != null && event.session!.user != null) {
        state = app.Authenticated(
          user: event.session!.user,
          session: event.session!,
        );
      } else {
        state = const app.Unauthenticated();
      }
    });
  }

  /// Sign in with email and password
  /// Returns error message if failed, null if success
  /// Only updates auth state on SUCCESS (to trigger navigation to home)
  /// Does NOT set AuthLoading or AuthError to avoid router flicker
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    // Don't set AuthLoading - let the form handle its own loading state
    // This prevents RouterRefreshNotifier from triggering unnecessary refreshes

    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        // Only set Authenticated state on success - this triggers redirect to home
        state = app.Authenticated(
          user: response.user!,
          session: response.session!,
        );

        // Sync push token and subscribe to gym topic after login
        try {
          await _ref.read(notificationProvider.notifier).syncToken();
        } catch (e) {
          debugPrint('Error syncing push token after login: $e');
        }
        return null; // Success
      } else {
        return 'No se pudo iniciar sesión. Intenta de nuevo.';
      }
    } on GymGoAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de conexión. Verifica tu internet e intenta de nuevo.';
    }
  }

  /// Send password reset email
  /// Returns a record with (success, errorMessage)
  /// Does NOT change global auth state to avoid router flicker
  Future<({bool success, String? error})> sendPasswordReset({required String email}) async {
    // Don't set AuthLoading - let the form handle its own loading state
    // This prevents RouterRefreshNotifier from triggering unnecessary redirects

    try {
      await _repository.sendPasswordResetEmail(email: email);
      // Don't set PasswordResetSent state - let the form handle success UI
      // This keeps auth state clean and avoids race conditions with Supabase listener
      return (success: true, error: null);
    } on GymGoAuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: 'No pudimos enviar el correo. Intenta de nuevo.');
    }
  }

  /// Update password
  Future<bool> updatePassword({required String newPassword}) async {
    state = const app.AuthLoading();

    try {
      await _repository.updatePassword(newPassword: newPassword);
      state = const app.PasswordResetSuccess();
      return true;
    } on GymGoAuthException catch (e) {
      state = app.AuthError(message: e.message, code: e.code);
      return false;
    } catch (e) {
      state = app.AuthError(message: e.toString());
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const app.AuthLoading();

    try {
      // Deactivate push token before signing out
      try {
        await _ref.read(notificationProvider.notifier).onLogout();
      } catch (e) {
        debugPrint('Error deactivating push token: $e');
        // Continue with sign out even if token deactivation fails
      }

      await _repository.signOut();
      state = const app.Unauthenticated();
    } on GymGoAuthException catch (e) {
      state = app.AuthError(message: e.message, code: e.code);
    } catch (e) {
      state = app.AuthError(message: e.toString());
    }
  }

  /// Reset state to unauthenticated (for navigation)
  void resetToUnauthenticated() {
    state = const app.Unauthenticated();
  }

  /// Clear error and reset to previous state
  void clearError() {
    if (_repository.isAuthenticated) {
      final session = _repository.currentSession!;
      final user = _repository.currentUser!;
      state = app.Authenticated(user: user, session: session);
    } else {
      state = const app.Unauthenticated();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for the AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, app.AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});

/// Helper provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is app.Authenticated;
});

/// Helper provider to get current user
final currentUserProvider = Provider<supabase.User?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is app.Authenticated) {
    return authState.user;
  }
  return null;
});
