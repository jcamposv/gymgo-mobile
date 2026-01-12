import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/models/member.dart';
import '../../../../shared/models/profile_photo_selection.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../../shared/providers/branding_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Profile screen with user info and settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Member? _member;
  bool _isLoadingMember = true;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoadingMember = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('members')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        debugPrint('Member data: $response');
        debugPrint('avatar_url from DB: ${response['avatar_url']}');
        final member = Member.fromJson(response);
        debugPrint('Parsed member - avatarPath: ${member.avatarPath}, profileImageUrl: ${member.profileImageUrl}');
        setState(() {
          _member = member;
          _isLoadingMember = false;
        });
      } else {
        // Create member from user data if not exists
        setState(() {
          _member = Member(
            id: user.id,
            name: user.email?.split('@').first ?? 'Usuario',
            email: user.email,
          );
          _isLoadingMember = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading member: $e');
      // Fallback to user data
      setState(() {
        _member = Member(
          id: user.id,
          name: user.email?.split('@').first ?? 'Usuario',
          email: user.email,
        );
        _isLoadingMember = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Center(
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
          const Icon(
            LucideIcons.building2,
            size: 20,
            color: GymGoColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String? email) {
    final name = _member?.name ?? email?.split('@').first ?? 'Usuario';
    final displayName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : 'Usuario';

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Row(
        children: [
          // Profile photo with edit functionality
          if (_isLoadingMember)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GymGoColors.primary,
                ),
              ),
            )
          else if (_member != null)
            MemberProfilePhoto(
              member: _member!,
              size: ProfilePhotoSize.large,
              customSize: 64,
              isEditable: true,
              showEditOverlay: true,
              onSave: _handleSaveProfilePhoto,
              onSavedOptimistic: _handleOptimisticUpdate,
            )
          else
            PhotoFallback(
              initials: displayName.substring(0, displayName.length >= 2 ? 2 : 1).toUpperCase(),
              size: 64,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
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
          // The edit button is now part of MemberProfilePhoto
          // Only show if not using MemberProfilePhoto
          if (_member == null)
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

  /// Handle optimistic UI update
  void _handleOptimisticUpdate(ProfilePhotoSelection selection) {
    if (_member == null) return;

    setState(() {
      _member = selection.when(
        none: () => _member!.copyWith(
          clearProfileImageUrl: true,
          clearAvatarPath: true,
        ),
        avatar: (path) => _member!.copyWith(
          avatarPath: path,
          clearProfileImageUrl: true,
        ),
        upload: (file, bytes) => _member!, // Keep current until upload completes
      );
    });
  }

  /// Handle save profile photo
  Future<void> _handleSaveProfilePhoto(ProfilePhotoSelection selection) async {
    if (_member == null) return;

    final supabase = Supabase.instance.client;

    await selection.when(
      none: () => _removeProfilePhoto(supabase),
      avatar: (path) => _setAvatarPath(supabase, path),
      upload: (file, bytes) => _uploadProfileImage(supabase, file),
    );
  }

  Future<void> _removeProfilePhoto(SupabaseClient supabase) async {
    if (_member == null) return;

    await supabase.from('members').update({
      'avatar_url': null,
    }).eq('id', _member!.id);

    setState(() {
      _member = _member!.copyWith(
        clearProfileImageUrl: true,
        clearAvatarPath: true,
      );
    });
  }

  Future<void> _setAvatarPath(SupabaseClient supabase, String avatarPath) async {
    if (_member == null) return;

    // Convert mobile path to web format: avatar_2/avatar_01.svg -> /avatar/avatar_01.svg
    final webAvatarUrl = avatarPath.replaceFirst('avatar_2/', '/avatar/');

    await supabase.from('members').update({
      'avatar_url': webAvatarUrl,
    }).eq('id', _member!.id);

    setState(() {
      _member = _member!.copyWith(
        avatarPath: avatarPath,
        clearProfileImageUrl: true,
      );
    });
  }

  Future<void> _uploadProfileImage(SupabaseClient supabase, File file) async {
    if (_member == null) return;

    final memberId = _member!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'profile_${memberId}_$timestamp.jpg';
    final storagePath = 'profiles/$memberId/$fileName';

    // Upload to Supabase Storage
    await supabase.storage.from('avatars').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    // Get public URL
    final publicUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);

    // Update member in database - web uses avatar_url for everything
    await supabase.from('members').update({
      'avatar_url': publicUrl,
    }).eq('id', _member!.id);

    setState(() {
      _member = _member!.copyWith(
        profileImageUrl: publicUrl,
        clearAvatarPath: true,
      );
    });
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
