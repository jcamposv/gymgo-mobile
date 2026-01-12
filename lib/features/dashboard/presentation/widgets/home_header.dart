import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/avatars.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/models/member.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../../shared/providers/branding_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Home header with gym logo, greeting, and user avatar
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({
    super.key,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  Member? _member;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('members')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _member = Member.fromJson(response);
        });
      }
    } catch (e) {
      debugPrint('Error loading member for header: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final brandingAsync = ref.watch(gymBrandingProvider);
    final userName = _member?.name ?? _extractUserName(user?.email);
    final greeting = _getGreeting();
    final gymName = brandingAsync.whenOrNull(data: (b) => b.gymName);

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
                    gymName,
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
            onTap: widget.onNotificationsTap,
            hasBadge: false, // TODO: Connect to notifications count
          ),

          const SizedBox(width: GymGoSpacing.xs),

          // User avatar
          _buildUserAvatar(user?.email),
        ],
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
      onTap: widget.onAvatarTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildAvatarContent(initials),
      ),
    );
  }

  Widget _buildAvatarContent(String initials) {
    // Check if member has profile image URL (uploaded photo)
    if (_member?.profileImageUrl != null && _member!.profileImageUrl!.isNotEmpty) {
      return Image.network(
        _member!.profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsFallback(initials),
      );
    }

    // Check if member has avatar path (predefined avatar)
    if (_member?.avatarPath != null && _member!.avatarPath!.isNotEmpty) {
      final assetPath = AvatarConfig.getAvatarUrl(_member!.avatarPath!);
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
