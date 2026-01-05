import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login form state
class LoginFormState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.isSubmitting = false,
    this.isValid = false,
  });

  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;
  final bool isSubmitting;
  final bool isValid;

  LoginFormState copyWith({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
    bool? isSubmitting,
    bool? isValid,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError,
      passwordError: passwordError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
    );
  }
}

/// Login form notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(const LoginFormState());

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Update email value
  void setEmail(String value) {
    final error = _validateEmail(value);
    state = state.copyWith(
      email: value,
      emailError: error,
      isValid: _isFormValid(value, state.password, error, state.passwordError),
    );
  }

  /// Update password value
  void setPassword(String value) {
    final error = _validatePassword(value);
    state = state.copyWith(
      password: value,
      passwordError: error,
      isValid: _isFormValid(state.email, value, state.emailError, error),
    );
  }

  /// Validate email
  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  /// Validate password
  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Check if form is valid
  bool _isFormValid(
    String email,
    String password,
    String? emailError,
    String? passwordError,
  ) {
    return email.isNotEmpty &&
        password.isNotEmpty &&
        emailError == null &&
        passwordError == null;
  }

  /// Set submitting state
  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  /// Validate all fields
  bool validateAll() {
    final emailError = _validateEmail(state.email);
    final passwordError = _validatePassword(state.password);

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
      isValid: emailError == null && passwordError == null,
    );

    return state.isValid;
  }

  /// Reset form
  void reset() {
    state = const LoginFormState();
  }
}

/// Provider for login form
final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});
