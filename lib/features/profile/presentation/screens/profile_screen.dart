import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../../shared/providers/branding_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Profile screen with user info and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final brandingAsync = ref.watch(gymBrandingProvider);
    final gymName = brandingAsync.whenOrNull(data: (b) => b.gymName) ?? 'GymGo';

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Column(
            children: [
              // Gym branding card
              _buildGymCard(gymName),

              const SizedBox(height: GymGoSpacing.lg),

              // User avatar and info
              _buildUserCard(user?.email),

              const SizedBox(height: GymGoSpacing.xl),

              // Settings sections
              _buildSettingsSection(
                title: 'Cuenta',
                items: [
                  _SettingsItem(
                    icon: LucideIcons.user,
                    label: 'Datos personales',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.lock,
                    label: 'Cambiar contraseña',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.bell,
                    label: 'Notificaciones',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: GymGoSpacing.lg),

              _buildSettingsSection(
                title: 'Preferencias',
                items: [
                  _SettingsItem(
                    icon: LucideIcons.languages,
                    label: 'Idioma',
                    trailing: 'Español',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.moon,
                    label: 'Tema oscuro',
                    trailing: 'Activado',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: GymGoSpacing.lg),

              _buildSettingsSection(
                title: 'Soporte',
                items: [
                  _SettingsItem(
                    icon: LucideIcons.helpCircle,
                    label: 'Ayuda',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.messageSquare,
                    label: 'Contactar soporte',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.fileText,
                    label: 'Términos y condiciones',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: GymGoSpacing.xl),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GymGoColors.error,
                    side: BorderSide(
                      color: GymGoColors.error.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: GymGoSpacing.lg),

              // App version
              Text(
                '$gymName Mobile v1.0.0',
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textTertiary,
                ),
              ),

              const SizedBox(height: GymGoSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGymCard(String gymName) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GymGoColors.cardBackground,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Center(
              child: GymLogo(
                height: 36,
                variant: GymLogoVariant.icon,
              ),
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gymName,
                  style: GymGoTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu gimnasio',
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.building2,
            size: 20,
            color: GymGoColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String? email) {
    final name = email?.split('@').first ?? 'Usuario';
    final initials = name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : 'U';

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: GymGoColors.primaryGradient,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: GymGoColors.background,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name[0].toUpperCase() + name.substring(1),
                  style: GymGoTypography.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? '',
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
                const SizedBox(height: GymGoSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                  child: Text(
                    'Miembro activo',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              LucideIcons.pencil,
              size: 18,
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: GymGoSpacing.xs,
            bottom: GymGoSpacing.sm,
          ),
          child: Text(
            title,
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ),
        GymGoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      top: index == 0
                          ? const Radius.circular(GymGoSpacing.radiusLg)
                          : Radius.zero,
                      bottom: isLast
                          ? const Radius.circular(GymGoSpacing.radiusLg)
                          : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GymGoSpacing.md,
                        vertical: GymGoSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: GymGoColors.textSecondary,
                          ),
                          const SizedBox(width: GymGoSpacing.md),
                          Expanded(
                            child: Text(
                              item.label,
                              style: GymGoTypography.bodyMedium,
                            ),
                          ),
                          if (item.trailing != null) ...[
                            Text(
                              item.trailing!,
                              style: GymGoTypography.bodySmall.copyWith(
                                color: GymGoColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: GymGoSpacing.xs),
                          ],
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: GymGoColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: GymGoColors.cardBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.surface,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.error,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
}
