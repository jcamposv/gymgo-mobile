import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/config/avatars.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../models/member.dart';
import '../../../models/profile_photo_selection.dart';
import 'photo_fallback.dart';
import 'profile_image_picker_sheet.dart';

/// Size variants for MemberProfilePhoto
enum ProfilePhotoSize {
  small(40, 14, GymGoSpacing.radiusMd),
  medium(56, 20, GymGoSpacing.radiusMd),
  large(72, 28, GymGoSpacing.radiusLg),
  extraLarge(96, 36, GymGoSpacing.radiusXl);

  const ProfilePhotoSize(this.pixels, this.fontSize, this.radius);

  final double pixels;
  final double fontSize;
  final double radius;
}

/// Reusable profile photo component for members
///
/// Display priority:
/// 1. profileImageUrl (if exists) - shows cached network image
/// 2. avatarPath (if exists) - shows predefined avatar
/// 3. fallback - shows gradient with initials
///
/// When tapped, opens a bottom sheet for photo selection
class MemberProfilePhoto extends StatelessWidget {
  const MemberProfilePhoto({
    super.key,
    required this.member,
    this.size = ProfilePhotoSize.large,
    this.customSize,
    this.borderRadius,
    this.showEditOverlay = true,
    this.isEditable = true,
    this.onSave,
    this.onSavedOptimistic,
    this.border,
    this.showBorder = false,
  });

  /// Member data
  final Member member;

  /// Preset size variant
  final ProfilePhotoSize size;

  /// Custom size (overrides preset)
  final double? customSize;

  /// Custom border radius
  final BorderRadius? borderRadius;

  /// Show camera icon overlay on hover/tap
  final bool showEditOverlay;

  /// Whether tapping opens the picker
  final bool isEditable;

  /// Callback for saving selection (required if editable)
  final Future<void> Function(ProfilePhotoSelection selection)? onSave;

  /// Optional optimistic update callback
  final void Function(ProfilePhotoSelection selection)? onSavedOptimistic;

  /// Custom border
  final Border? border;

  /// Show default border
  final bool showBorder;

  double get _size => customSize ?? size.pixels;
  double get _fontSize => customSize != null ? customSize! * 0.35 : size.fontSize;
  BorderRadius get _borderRadius =>
      borderRadius ?? BorderRadius.circular(size.radius);

  @override
  Widget build(BuildContext context) {
    Widget content = _buildContent();

    // Add border if specified
    if (showBorder || border != null) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
          border: border ??
              Border.all(
                color: GymGoColors.cardBorder,
                width: 2,
              ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size.radius - 2),
          child: content,
        ),
      );
    }

    // Make tappable if editable
    if (isEditable && onSave != null) {
      return Semantics(
        label: 'Cambiar foto de perfil',
        button: true,
        child: _TappablePhoto(
          size: _size,
          borderRadius: _borderRadius,
          showEditOverlay: showEditOverlay,
          onTap: () => _openPicker(context),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildContent() {
    // Priority 1: Profile image URL
    if (member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty) {
      return _buildNetworkImage(member.profileImageUrl!);
    }

    // Priority 2: Avatar path
    if (member.avatarPath != null && member.avatarPath!.isNotEmpty) {
      return _buildAvatar(member.avatarPath!);
    }

    // Priority 3: Fallback with initials
    return PhotoFallback(
      initials: member.initials,
      size: _size,
      borderRadius: _borderRadius,
      fontSize: _fontSize,
    );
  }

  Widget _buildNetworkImage(String url) {
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildLoadingPlaceholder(),
          errorWidget: (_, __, ___) => PhotoFallback(
            initials: member.initials,
            size: _size,
            borderRadius: _borderRadius,
            fontSize: _fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatarPath) {
    final fullPath = AvatarConfig.getAvatarUrl(avatarPath);

    return SizedBox(
      width: _size,
      height: _size,
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Container(
          color: GymGoColors.surface,
          padding: EdgeInsets.all(_size * 0.1),
          child: _buildAvatarContent(fullPath, avatarPath),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String fullPath, String avatarPath) {
    // SVG avatar
    if (avatarPath.endsWith('.svg')) {
      if (fullPath.startsWith('assets/')) {
        return SvgPicture.asset(
          fullPath,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _buildLoadingPlaceholder(),
        );
      }
      return SvgPicture.network(
        fullPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _buildLoadingPlaceholder(),
      );
    }

    // Regular image avatar
    if (fullPath.startsWith('assets/')) {
      return Image.asset(
        fullPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }

    return CachedNetworkImage(
      imageUrl: fullPath,
      fit: BoxFit.contain,
      placeholder: (_, __) => _buildLoadingPlaceholder(),
      errorWidget: (_, __, ___) => _buildFallbackIcon(),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: _borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: GymGoColors.primary,
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        LucideIcons.user,
        size: _size * 0.4,
        color: GymGoColors.textTertiary,
      ),
    );
  }

  void _openPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    ProfileImagePickerSheet.show(
      context: context,
      member: member,
      onSave: onSave!,
      onSavedOptimistic: onSavedOptimistic,
    );
  }
}

/// Tappable wrapper with ripple and optional edit overlay
class _TappablePhoto extends StatefulWidget {
  const _TappablePhoto({
    required this.child,
    required this.size,
    required this.borderRadius,
    required this.showEditOverlay,
    required this.onTap,
  });

  final Widget child;
  final double size;
  final BorderRadius borderRadius;
  final bool showEditOverlay;
  final VoidCallback onTap;

  @override
  State<_TappablePhoto> createState() => _TappablePhotoState();
}

class _TappablePhotoState extends State<_TappablePhoto> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Photo content
          AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: widget.child,
          ),
          // Edit overlay
          if (widget.showEditOverlay)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isPressed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: widget.borderRadius,
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GymGoColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        color: GymGoColors.background,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Always visible edit badge (small)
          if (widget.showEditOverlay)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: GymGoColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GymGoColors.background,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  LucideIcons.pencil,
                  color: GymGoColors.background,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simple non-editable profile photo display
/// Use this when you just need to show the photo without edit functionality
class MemberProfilePhotoDisplay extends StatelessWidget {
  const MemberProfilePhotoDisplay({
    super.key,
    required this.memberName,
    this.profileImageUrl,
    this.avatarPath,
    this.size = ProfilePhotoSize.medium,
    this.customSize,
    this.borderRadius,
    this.border,
  });

  final String memberName;
  final String? profileImageUrl;
  final String? avatarPath;
  final ProfilePhotoSize size;
  final double? customSize;
  final BorderRadius? borderRadius;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    // Create a minimal member for display
    final member = Member(
      id: '',
      name: memberName,
      profileImageUrl: profileImageUrl,
      avatarPath: avatarPath,
    );

    return MemberProfilePhoto(
      member: member,
      size: size,
      customSize: customSize,
      borderRadius: borderRadius,
      border: border,
      isEditable: false,
      showEditOverlay: false,
    );
  }
}
