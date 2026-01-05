import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reset password form state
class ResetPasswordFormState {
  const ResetPasswordFormState({
    this.password = '',
    this.confirmPassword = '',
    this.passwordError,
    this.confirmPasswordError,
    this.isSubmitting = false,
    this.isValid = false,
    this.isSuccess = false,
  });

  final String password;
  final String confirmPassword;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isSubmitting;
  final bool isValid;
  final bool isSuccess;

  ResetPasswordFormState copyWith({
    String? password,
    String? confirmPassword,
    String? passwordError,
    String? confirmPasswordError,
    bool? isSubmitting,
    bool? isValid,
    bool? isSuccess,
  }) {
    return ResetPasswordFormState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Reset password form notifier
class ResetPasswordFormNotifier extends StateNotifier<ResetPasswordFormState> {
  ResetPasswordFormNotifier() : super(const ResetPasswordFormState());

  /// Update password value
  void setPassword(String value) {
    final error = _validatePassword(value);
    final confirmError = _validateConfirmPassword(state.confirmPassword, value);
    state = state.copyWith(
      password: value,
      passwordError: error,
      confirmPasswordError: confirmError,
      isValid: _isFormValid(error, confirmError, value, state.confirmPassword),
    );
  }

  /// Update confirm password value
  void setConfirmPassword(String value) {
    final error = _validateConfirmPassword(value, state.password);
    state = state.copyWith(
      confirmPassword: value,
      confirmPasswordError: error,
      isValid: _isFormValid(state.passwordError, error, state.password, value),
    );
  }

  /// Validate password
  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe tener al menos una mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe tener al menos un número';
    }
    return null;
  }

  /// Validate confirm password
  String? _validateConfirmPassword(String value, String password) {
    if (value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Check if form is valid
  bool _isFormValid(
    String? passwordError,
    String? confirmPasswordError,
    String password,
    String confirmPassword,
  ) {
    return password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        passwordError == null &&
        confirmPasswordError == null;
  }

  /// Set submitting state
  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  /// Set success state
  void setSuccess(bool value) {
    state = state.copyWith(isSuccess: value);
  }

  /// Validate all fields
  bool validateAll() {
    final passwordError = _validatePassword(state.password);
    final confirmPasswordError =
        _validateConfirmPassword(state.confirmPassword, state.password);

    state = state.copyWith(
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      isValid: passwordError == null && confirmPasswordError == null,
    );

    return state.isValid;
  }

  /// Reset form
  void reset() {
    state = const ResetPasswordFormState();
  }
}

/// Provider for reset password form
final resetPasswordFormProvider = StateNotifierProvider.autoDispose<
    ResetPasswordFormNotifier, ResetPasswordFormState>((ref) {
  return ResetPasswordFormNotifier();
});
