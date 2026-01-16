import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Bottom sheet for changing password
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  /// Show the change password bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymGoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      builder: (context) => const ChangePasswordSheet(),
    );
  }

  @override
  ConsumerState<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Minimum password length (match backend rules)
  static const int _minPasswordLength = 6;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña actual';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una nueva contraseña';
    }
    if (value.length < _minPasswordLength) {
      return 'La contraseña debe tener al menos $_minPasswordLength caracteres';
    }
    if (value == _currentPasswordController.text) {
      return 'La nueva contraseña debe ser diferente a la actual';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu nueva contraseña';
    }
    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _handleChangePassword() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user?.email == null) {
        throw Exception('No se encontró el usuario');
      }

      // Verify current password by re-authenticating
      await Supabase.instance.client.auth.signInWithPassword(
        email: user!.email!,
        password: _currentPasswordController.text,
      );

      // Update to new password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contraseña actualizada'),
            backgroundColor: GymGoColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(GymGoSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.toLowerCase().contains('invalid') ||
            e.message.toLowerCase().contains('credentials')) {
          _errorMessage = 'Contraseña actual incorrecta';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cambiar la contraseña. Intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GymGoColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: GymGoSpacing.lg),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(GymGoSpacing.sm),
                      decoration: BoxDecoration(
                        color: GymGoColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                      ),
                      child: const Icon(
                        LucideIcons.lock,
                        color: GymGoColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: GymGoSpacing.md),
                    Text(
                      'Cambiar contraseña',
                      style: GymGoTypography.headlineSmall,
                    ),
                  ],
                ),

                const SizedBox(height: GymGoSpacing.lg),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(GymGoSpacing.md),
                    decoration: BoxDecoration(
                      color: GymGoColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                      border: Border.all(
                        color: GymGoColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: GymGoColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: GymGoSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GymGoTypography.bodySmall.copyWith(
                              color: GymGoColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.md),
                ],

                // Current password
                GymGoPasswordField(
                  controller: _currentPasswordController,
                  label: 'Contraseña actual',
                  hint: 'Ingresa tu contraseña actual',
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  validator: _validateCurrentPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),

                const SizedBox(height: GymGoSpacing.md),

                // New password
                GymGoPasswordField(
                  controller: _newPasswordController,
                  label: 'Nueva contraseña',
                  hint: 'Mínimo $_minPasswordLength caracteres',
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  validator: _validateNewPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),

                const SizedBox(height: GymGoSpacing.md),

                // Confirm password
                GymGoPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar contraseña',
                  hint: 'Repite la nueva contraseña',
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirmPassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onSubmitted: (_) => _handleChangePassword(),
                ),

                const SizedBox(height: GymGoSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: GymGoColors.cardBorder),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: GymGoSpacing.md),
                    Expanded(
                      child: GymGoPrimaryButton(
                        text: 'Guardar',
                        onPressed: _isLoading ? null : _handleChangePassword,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: GymGoSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
