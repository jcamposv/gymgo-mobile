import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication state for the app
sealed class AuthState {
  const AuthState();
}

/// Initial loading state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during auth operations
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state with user and session
class Authenticated extends AuthState {
  const Authenticated({
    required this.user,
    required this.session,
  });

  final User user;
  final Session session;
}

/// Unauthenticated state
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication error state
class AuthError extends AuthState {
  const AuthError({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;
}

/// Password reset email sent
class PasswordResetSent extends AuthState {
  const PasswordResetSent({required this.email});

  final String email;
}

/// Password reset successful
class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}
