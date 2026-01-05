import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env_config.dart';
import '../../../core/config/supabase_config.dart';
import '../domain/auth_exception.dart';

/// Repository for authentication operations
class AuthRepository {
  AuthRepository();

  final _auth = SupabaseConfig.auth;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw const GymGoAuthException(
          message: 'No se pudo iniciar sesión. Intenta de nuevo.',
        );
      }

      return response;
    } on AuthException catch (e) {
      throw GymGoAuthException.fromSupabase(e);
    } catch (e) {
      if (e is GymGoAuthException) rethrow;
      throw GymGoAuthException(message: e.toString());
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: EnvConfig.supabaseRedirectUrl,
      );
    } on AuthException catch (e) {
      throw GymGoAuthException.fromSupabase(e);
    } catch (e) {
      if (e is GymGoAuthException) rethrow;
      throw GymGoAuthException(message: e.toString());
    }
  }

  /// Update password (after reset link)
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    try {
      await _auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw GymGoAuthException.fromSupabase(e);
    } catch (e) {
      if (e is GymGoAuthException) rethrow;
      throw GymGoAuthException(message: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw GymGoAuthException.fromSupabase(e);
    } catch (e) {
      if (e is GymGoAuthException) rethrow;
      throw GymGoAuthException(message: e.toString());
    }
  }

  /// Get current session
  Session? get currentSession => _auth.currentSession;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _auth.refreshSession();
      return response;
    } on AuthException catch (e) {
      throw GymGoAuthException.fromSupabase(e);
    } catch (e) {
      if (e is GymGoAuthException) rethrow;
      throw GymGoAuthException(message: e.toString());
    }
  }
}
