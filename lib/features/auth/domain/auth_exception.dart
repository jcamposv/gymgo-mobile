import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Custom authentication exception for GymGo
class GymGoAuthException implements Exception {
  const GymGoAuthException({
    required this.message,
    this.code,
  });

  final String message;
  final String? code;

  /// Create from Supabase exception
  factory GymGoAuthException.fromSupabase(dynamic error) {
    if (error is supabase.AuthException) {
      return GymGoAuthException(
        message: _translateError(error.message),
        code: error.code,
      );
    }
    return GymGoAuthException(
      message: error.toString(),
    );
  }

  /// Translate common Supabase error messages to Spanish
  static String _translateError(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials')) {
      return 'Correo electrónico o contraseña incorrectos';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return 'Por favor confirma tu correo electrónico antes de iniciar sesión';
    }
    if (lowerMessage.contains('user not found')) {
      return 'No se encontró una cuenta con este correo electrónico';
    }
    if (lowerMessage.contains('invalid email')) {
      return 'El correo electrónico no es válido';
    }
    if (lowerMessage.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (lowerMessage.contains('rate limit') || lowerMessage.contains('too many')) {
      return 'Demasiados intentos. Por favor espera un momento';
    }
    if (lowerMessage.contains('network') || lowerMessage.contains('connection')) {
      return 'Error de conexión. Verifica tu internet';
    }
    if (lowerMessage.contains('session expired') || lowerMessage.contains('refresh')) {
      return 'Tu sesión ha expirado. Por favor inicia sesión de nuevo';
    }

    return message;
  }

  @override
  String toString() => message;
}
