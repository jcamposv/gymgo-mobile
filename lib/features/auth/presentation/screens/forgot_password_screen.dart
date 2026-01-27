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
import '../providers/auth_providers.dart';
import '../providers/forgot_password_provider.dart';

/// Forgot password screen for GymGo
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    ref.read(forgotPasswordFormProvider.notifier).setEmail(value);
  }

  Future<void> _handleSendResetEmail() async {
    // Validate form
    if (!ref.read(forgotPasswordFormProvider.notifier).validate()) {
      return;
    }

    final formState = ref.read(forgotPasswordFormProvider);
    ref.read(forgotPasswordFormProvider.notifier).setSubmitting(true);

    // Send reset email
    final result = await ref.read(authProvider.notifier).sendPasswordReset(
          email: formState.email,
        );

    ref.read(forgotPasswordFormProvider.notifier).setSubmitting(false);

    if (result.success) {
      ref.read(forgotPasswordFormProvider.notifier).setSuccess(true);
    } else if (result.error != null && mounted) {
      // Show error message
      GymGoToast.error(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(forgotPasswordFormProvider);
    // Use only form's submitting state - not global auth state
    // This prevents flicker from auth state changes
    final isLoading = formState.isSubmitting;

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
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

  Widget _buildFormState(ForgotPasswordFormState formState, bool isLoading) {
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

        // Back to login
        _buildBackToLogin().animate().fadeIn(
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
            LucideIcons.mailCheck,
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
          '¡Correo enviado!',
          style: GymGoTypography.headlineLarge,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: GymGoSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.lg),
          child: Text(
            'Si el correo existe en nuestro sistema, recibirás un enlace para restablecer tu contraseña.',
            style: GymGoTypography.bodyLarge.copyWith(
              color: GymGoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: GymGoSpacing.xxl),

        // Back to login button
        GymGoPrimaryButton(
          text: 'Volver a iniciar sesión',
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
            LucideIcons.keyRound,
            size: 32,
            color: GymGoColors.primary,
          ),
        ),
        const SizedBox(height: GymGoSpacing.lg),
        const GymGoHeader(
          title: 'Recuperar contraseña',
          subtitle: 'Te enviaremos un enlace para restablecer tu contraseña.',
          alignment: CrossAxisAlignment.center,
        ),
      ],
    );
  }

  Widget _buildForm(ForgotPasswordFormState formState, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field
        GymGoTextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          label: 'Correo electrónico',
          hint: 'tu@email.com',
          errorText: formState.emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          prefixIcon: const Icon(
            LucideIcons.mail,
            size: GymGoSpacing.iconMd,
            color: GymGoColors.textTertiary,
          ),
          onChanged: _onEmailChanged,
          onSubmitted: (_) => _handleSendResetEmail(),
        ),

        const SizedBox(height: GymGoSpacing.xl),

        // Send button
        GymGoPrimaryButton(
          text: 'Enviar enlace',
          isLoading: isLoading,
          isEnabled: formState.isValid && !isLoading,
          onPressed: _handleSendResetEmail,
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return Center(
      child: GymGoTextButton(
        text: 'Volver a iniciar sesión',
        icon: LucideIcons.arrowLeft,
        onPressed: () => context.go(Routes.login),
      ),
    );
  }
}
