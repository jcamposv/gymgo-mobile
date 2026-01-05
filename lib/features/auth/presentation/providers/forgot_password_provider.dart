import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Forgot password form state
class ForgotPasswordFormState {
  const ForgotPasswordFormState({
    this.email = '',
    this.emailError,
    this.isSubmitting = false,
    this.isValid = false,
    this.isSuccess = false,
  });

  final String email;
  final String? emailError;
  final bool isSubmitting;
  final bool isValid;
  final bool isSuccess;

  ForgotPasswordFormState copyWith({
    String? email,
    String? emailError,
    bool? isSubmitting,
    bool? isValid,
    bool? isSuccess,
  }) {
    return ForgotPasswordFormState(
      email: email ?? this.email,
      emailError: emailError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Forgot password form notifier
class ForgotPasswordFormNotifier extends StateNotifier<ForgotPasswordFormState> {
  ForgotPasswordFormNotifier() : super(const ForgotPasswordFormState());

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Update email value
  void setEmail(String value) {
    final error = _validateEmail(value);
    state = state.copyWith(
      email: value,
      emailError: error,
      isValid: error == null && value.isNotEmpty,
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

  /// Set submitting state
  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  /// Set success state
  void setSuccess(bool value) {
    state = state.copyWith(isSuccess: value);
  }

  /// Validate form
  bool validate() {
    final emailError = _validateEmail(state.email);
    state = state.copyWith(
      emailError: emailError,
      isValid: emailError == null,
    );
    return state.isValid;
  }

  /// Reset form
  void reset() {
    state = const ForgotPasswordFormState();
  }
}

/// Provider for forgot password form
final forgotPasswordFormProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordFormNotifier, ForgotPasswordFormState>((ref) {
  return ForgotPasswordFormNotifier();
});
