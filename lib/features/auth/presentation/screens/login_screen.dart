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
import '../providers/login_form_provider.dart';

/// Login screen for GymGo
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    ref.read(loginFormProvider.notifier).setEmail(value);
  }

  void _onPasswordChanged(String value) {
    ref.read(loginFormProvider.notifier).setPassword(value);
  }

  Future<void> _handleLogin() async {
    // Validate form
    if (!ref.read(loginFormProvider.notifier).validateAll()) {
      return;
    }

    final formState = ref.read(loginFormProvider);

    // Attempt login
    await ref.read(authProvider.notifier).signIn(
          email: formState.email,
          password: formState.password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState is app.AuthLoading;

    // Listen for auth errors
    ref.listen<app.AuthState>(authProvider, (previous, next) {
      if (next is app.AuthError) {
        GymGoToast.error(context, next.message);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Logo and header
                      _buildHeader().animate().fadeIn(
                            duration: 400.ms,
                            delay: 100.ms,
                          ),

                      const SizedBox(height: GymGoSpacing.xxl),

                      // Login form
                      _buildForm(formState, isLoading).animate().fadeIn(
                            duration: 400.ms,
                            delay: 200.ms,
                          ),

                      const SizedBox(height: GymGoSpacing.lg),

                      // Forgot password link
                      _buildForgotPasswordLink().animate().fadeIn(
                            duration: 400.ms,
                            delay: 300.ms,
                          ),

                      const Spacer(flex: 2),

                      // Footer
                      _buildFooter().animate().fadeIn(
                            duration: 400.ms,
                            delay: 400.ms,
                          ),

                      const SizedBox(height: GymGoSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Dynamic gym logo - shows gym's logo if configured, falls back to default
        const GymLogo(
          height: 48,
          variant: GymLogoVariant.full,
        ),
        const SizedBox(height: GymGoSpacing.xl),
        const GymGoHeader(
          title: 'Iniciar sesión',
          subtitle: 'Accede a tu cuenta para ver tus rutinas y progreso.',
          alignment: CrossAxisAlignment.center,
        ),
      ],
    );
  }

  Widget _buildForm(LoginFormState formState, bool isLoading) {
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
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          prefixIcon: const Icon(
            LucideIcons.mail,
            size: GymGoSpacing.iconMd,
            color: GymGoColors.textTertiary,
          ),
          onChanged: _onEmailChanged,
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
        ),

        const SizedBox(height: GymGoSpacing.lg),

        // Password field
        GymGoPasswordField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Contraseña',
          hint: 'Tu contraseña',
          errorText: formState.passwordError,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onChanged: _onPasswordChanged,
          onSubmitted: (_) => _handleLogin(),
        ),

        const SizedBox(height: GymGoSpacing.xl),

        // Login button
        GymGoPrimaryButton(
          text: 'Entrar',
          isLoading: isLoading,
          isEnabled: formState.isValid && !isLoading,
          onPressed: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GymGoTextButton(
        text: '¿Olvidaste tu contraseña?',
        onPressed: () => context.push(Routes.forgotPassword),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.shieldCheck,
              size: GymGoSpacing.iconSm,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(width: GymGoSpacing.xs),
            Text(
              'Conexión segura',
              style: GymGoTypography.labelSmall.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
