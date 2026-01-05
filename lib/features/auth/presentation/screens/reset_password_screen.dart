import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/auth_state.dart' as app;
import '../providers/auth_providers.dart';
import '../providers/reset_password_provider.dart';

/// Reset password screen for GymGo
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    ref.read(resetPasswordFormProvider.notifier).setPassword(value);
  }

  void _onConfirmPasswordChanged(String value) {
    ref.read(resetPasswordFormProvider.notifier).setConfirmPassword(value);
  }

  Future<void> _handleUpdatePassword() async {
    // Validate form
    if (!ref.read(resetPasswordFormProvider.notifier).validateAll()) {
      return;
    }

    final formState = ref.read(resetPasswordFormProvider);
    ref.read(resetPasswordFormProvider.notifier).setSubmitting(true);

    // Update password
    final success = await ref.read(authProvider.notifier).updatePassword(
          newPassword: formState.password,
        );

    ref.read(resetPasswordFormProvider.notifier).setSubmitting(false);

    if (success) {
      ref.read(resetPasswordFormProvider.notifier).setSuccess(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(resetPasswordFormProvider);
    final authState = ref.watch(authProvider);
    final isLoading = formState.isSubmitting || authState is app.AuthLoading;

    // Listen for auth errors
    ref.listen<app.AuthState>(authProvider, (previous, next) {
      if (next is app.AuthError) {
        GymGoToast.error(context, next.message);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go(Routes.login),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - kToolbarHeight,
                ),
                child: IntrinsicHeight(
                  child: formState.isSuccess
                      ? _buildSuccessState()
                      : _buildFormState(formState, isLoading),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormState(ResetPasswordFormState formState, bool isLoading) {
    return Column(
      children: [
        const Spacer(flex: 1),

        // Icon and header
        _buildHeader().animate().fadeIn(
              duration: 400.ms,
              delay: 100.ms,
            ),

        const SizedBox(height: GymGoSpacing.xxl),

        // Form
        _buildForm(formState, isLoading).animate().fadeIn(
              duration: 400.ms,
              delay: 200.ms,
            ),

        const SizedBox(height: GymGoSpacing.lg),

        // Password requirements
        _buildPasswordRequirements().animate().fadeIn(
              duration: 400.ms,
              delay: 300.ms,
            ),

        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const Spacer(flex: 1),

        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: GymGoColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.checkCircle,
            size: 40,
            color: GymGoColors.success,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(),

        const SizedBox(height: GymGoSpacing.xl),

        // Success message
        Text(
          '¡Contraseña actualizada!',
          style: GymGoTypography.headlineLarge,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: GymGoSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.lg),
          child: Text(
            'Tu contraseña ha sido actualizada correctamente. Ya puedes iniciar sesión con tu nueva contraseña.',
            style: GymGoTypography.bodyLarge.copyWith(
              color: GymGoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: GymGoSpacing.xxl),

        // Go to login button
        GymGoPrimaryButton(
          text: 'Iniciar sesión',
          onPressed: () => context.go(Routes.login),
        ).animate().fadeIn(delay: 400.ms),

        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: GymGoColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.lock,
            size: 32,
            color: GymGoColors.primary,
          ),
        ),
        const SizedBox(height: GymGoSpacing.lg),
        const GymGoHeader(
          title: 'Nueva contraseña',
          subtitle: 'Crea una nueva contraseña segura para tu cuenta.',
          alignment: CrossAxisAlignment.center,
        ),
      ],
    );
  }

  Widget _buildForm(ResetPasswordFormState formState, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // New password field
        GymGoPasswordField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Nueva contraseña',
          hint: 'Ingresa tu nueva contraseña',
          errorText: formState.passwordError,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          onChanged: _onPasswordChanged,
          onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
        ),

        const SizedBox(height: GymGoSpacing.lg),

        // Confirm password field
        GymGoPasswordField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          label: 'Confirmar contraseña',
          hint: 'Repite tu nueva contraseña',
          errorText: formState.confirmPasswordError,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onChanged: _onConfirmPasswordChanged,
          onSubmitted: (_) => _handleUpdatePassword(),
        ),

        const SizedBox(height: GymGoSpacing.xl),

        // Update button
        GymGoPrimaryButton(
          text: 'Actualizar contraseña',
          isLoading: isLoading,
          isEnabled: formState.isValid && !isLoading,
          onPressed: _handleUpdatePassword,
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final formState = ref.watch(resetPasswordFormProvider);
    final password = formState.password;

    final requirements = [
      (
        'Al menos 6 caracteres',
        password.length >= 6,
      ),
      (
        'Una letra mayúscula',
        RegExp(r'[A-Z]').hasMatch(password),
      ),
      (
        'Un número',
        RegExp(r'[0-9]').hasMatch(password),
      ),
    ];

    return GymGoCard(
      backgroundColor: GymGoColors.surface,
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de la contraseña',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.sm),
          ...requirements.map((req) => _buildRequirementItem(req.$1, req.$2)),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.xxs),
      child: Row(
        children: [
          Icon(
            isMet ? LucideIcons.checkCircle2 : LucideIcons.circle,
            size: GymGoSpacing.iconSm,
            color: isMet ? GymGoColors.success : GymGoColors.textTertiary,
          ),
          const SizedBox(width: GymGoSpacing.xs),
          Text(
            text,
            style: GymGoTypography.bodySmall.copyWith(
              color: isMet ? GymGoColors.success : GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
