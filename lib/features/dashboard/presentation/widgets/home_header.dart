import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Home header with gym logo, greeting, and user avatar
class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    this.gymName,
    this.gymLogoUrl,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final String? gymName;
  final String? gymLogoUrl;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = _extractUserName(user?.email);
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          // Gym logo or default
          _buildGymLogo(),

          const SizedBox(width: GymGoSpacing.md),

          // Greeting and gym name
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
                if (gymName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    gymName!,
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Notifications button
          _buildIconButton(
            icon: LucideIcons.bell,
            onTap: onNotificationsTap,
            hasBadge: false, // TODO: Connect to notifications count
          ),

          const SizedBox(width: GymGoSpacing.xs),

          // User avatar
          _buildUserAvatar(user?.email),
        ],
      ),
    );
  }

  Widget _buildGymLogo() {
    if (gymLogoUrl != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          color: GymGoColors.cardBackground,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          gymLogoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultLogo(),
        ),
      );
    }
    return _defaultLogo();
  }

  Widget _defaultLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GymGoColors.primary,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: GymGoColors.background,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    bool hasBadge = false,
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
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: GymGoColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? email) {
    final initials = _getInitials(email);

    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GymGoColors.primary,
              GymGoColors.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
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
