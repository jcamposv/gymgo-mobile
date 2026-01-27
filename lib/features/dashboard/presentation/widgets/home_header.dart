import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/config/avatars.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/models/member.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../../shared/providers/branding_providers.dart';
import '../../../../shared/providers/location_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/inbox_providers.dart';
import '../../../profile/presentation/providers/member_providers.dart';

/// Home header with gym logo, greeting, and user avatar
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final brandingAsync = ref.watch(gymBrandingProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final locationAsync = ref.watch(currentLocationProvider);
    // Use the provider for member data - auto-updates when profile changes
    final memberAsync = ref.watch(currentMemberProvider);
    final member = memberAsync.valueOrNull;
    final userName = member?.name ?? _extractUserName(user?.email);
    final greeting = _getGreeting();
    final gymName = brandingAsync.whenOrNull(data: (b) => b.gymName);
    final locationName = locationAsync.whenOrNull(data: (l) => l?.name);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          // Gym logo - uses GymLogo widget with branding provider
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              color: GymGoColors.cardBackground,
            ),
            clipBehavior: Clip.antiAlias,
            child: const Center(
              child: GymLogo(
                height: 36,
                variant: GymLogoVariant.icon,
              ),
            ),
          ),

          const SizedBox(width: GymGoSpacing.md),

          // Greeting, gym name, and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName',
                  style: GymGoTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (gymName != null || locationName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (gymName != null)
                        Flexible(
                          child: Text(
                            gymName,
                            style: GymGoTypography.bodySmall.copyWith(
                              color: GymGoColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (gymName != null && locationName != null) ...[
                        Text(
                          ' · ',
                          style: GymGoTypography.bodySmall.copyWith(
                            color: GymGoColors.textTertiary,
                          ),
                        ),
                      ],
                      if (locationName != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: GymGoColors.textTertiary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              locationName,
                              style: GymGoTypography.bodySmall.copyWith(
                                color: GymGoColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Notifications button
          Semantics(
            label: unreadCount > 0
                ? 'Notificaciones, $unreadCount sin leer'
                : 'Notificaciones',
            button: true,
            child: _buildIconButton(
              icon: LucideIcons.bell,
              onTap: () => context.push(Routes.notifications),
              hasBadge: unreadCount > 0,
              badgeCount: unreadCount,
            ),
          ),

          const SizedBox(width: GymGoSpacing.xs),

          // User avatar
          _buildUserAvatar(member, user?.email),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    bool hasBadge = false,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: GymGoColors.cardBackground,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(
            color: GymGoColors.cardBorder,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                size: 20,
                color: GymGoColors.textSecondary,
              ),
            ),
            if (hasBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(badgeCount > 9 ? 2 : 4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.error,
                    shape: badgeCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: badgeCount > 9 ? BorderRadius.circular(8) : null,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Member? member, String? email) {
    final initials = _getInitials(email);

    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildAvatarContent(member, initials),
      ),
    );
  }

  Widget _buildAvatarContent(Member? member, String initials) {
    // Check if member has profile image URL (uploaded photo)
    if (member?.profileImageUrl != null && member!.profileImageUrl!.isNotEmpty) {
      return Image.network(
        member.profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(initials),
      );
    }

    // Check if member has avatar path (predefined avatar)
    if (member?.avatarPath != null && member!.avatarPath!.isNotEmpty) {
      final assetPath = AvatarConfig.getAvatarUrl(member.avatarPath!);
      return SvgPicture.asset(
        assetPath,
        fit: BoxFit.cover,
      );
    }

    // Fallback to initials
    return _buildInitialsFallback(initials);
  }

  Widget _buildInitialsFallback(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GymGoColors.primary,
            GymGoColors.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: GymGoColors.background,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _extractUserName(String? email) {
    if (email == null) return 'Usuario';
    final name = email.split('@').first;
    // Capitalize first letter
    if (name.isEmpty) return 'Usuario';
    return name[0].toUpperCase() + name.substring(1);
  }

  String _getInitials(String? email) {
    if (email == null) return 'U';
    final name = email.split('@').first;
    if (name.isEmpty) return 'U';
    if (name.length == 1) return name.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
