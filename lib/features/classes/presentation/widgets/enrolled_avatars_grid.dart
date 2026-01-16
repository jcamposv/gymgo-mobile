import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Simple member data for avatar display
class EnrolledMember {
  const EnrolledMember({
    required this.id,
    this.avatarUrl,
    this.fullName,
  });

  final String id;
  final String? avatarUrl;
  final String? fullName;
}

/// Grid of enrolled member avatars showing capacity slots (matching reference design)
class EnrolledAvatarsGrid extends StatelessWidget {
  const EnrolledAvatarsGrid({
    super.key,
    required this.members,
    this.capacity = 20,
    this.maxVisible = 18,
    this.avatarSize = 48.0,
    this.spacing = 6.0,
    this.columns = 6,
    this.onTap,
  });

  final List<EnrolledMember> members;
  final int capacity;
  final int maxVisible;
  final double avatarSize;
  final double spacing;
  final int columns;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Show slots up to maxVisible or capacity, whichever is smaller
    final totalSlots = capacity > maxVisible ? maxVisible : capacity;

    return GestureDetector(
      onTap: onTap,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(totalSlots, (index) {
          if (index < members.length) {
            // Show member avatar
            return _AvatarItem(
              member: members[index],
              size: avatarSize,
            );
          } else {
            // Show empty slot
            return _EmptySlot(size: avatarSize);
          }
        }),
      ),
    );
  }
}

/// Empty slot placeholder
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        border: Border.all(
          color: GymGoColors.cardBorder,
          width: 1,
        ),
      ),
    );
  }
}

/// Individual avatar item
class _AvatarItem extends StatelessWidget {
  const _AvatarItem({
    required this.member,
    required this.size,
  });

  final EnrolledMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        border: Border.all(
          color: GymGoColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm - 1),
        child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: member.avatarUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholder(),
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: GymGoColors.surfaceLight,
      child: Icon(
        LucideIcons.user,
        size: size * 0.5,
        color: GymGoColors.textTertiary,
      ),
    );
  }
}

/// +X overflow bubble indicator
class _OverflowBubble extends StatelessWidget {
  const _OverflowBubble({
    required this.count,
    required this.size,
  });

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GymGoColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        border: Border.all(
          color: GymGoColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: size > 30 ? 11 : 9,
          ),
        ),
      ),
    );
  }
}

/// Horizontal avatar stack (alternative layout)
class EnrolledAvatarsStack extends StatelessWidget {
  const EnrolledAvatarsStack({
    super.key,
    required this.members,
    this.maxVisible = 5,
    this.avatarSize = 32.0,
    this.overlap = 10.0,
    this.onTap,
  });

  final List<EnrolledMember> members;
  final int maxVisible;
  final double avatarSize;
  final double overlap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCount = members.length > maxVisible ? maxVisible : members.length;
    final remainingCount = members.length - displayCount;
    final totalWidth = avatarSize + (displayCount - 1) * (avatarSize - overlap) +
        (remainingCount > 0 ? avatarSize - overlap : 0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: totalWidth,
        height: avatarSize,
        child: Stack(
          children: [
            ...List.generate(displayCount, (index) {
              return Positioned(
                left: index * (avatarSize - overlap),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GymGoColors.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: members[index].avatarUrl != null &&
                           members[index].avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: members[index].avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildCircularPlaceholder(),
                            errorWidget: (_, __, ___) => _buildCircularPlaceholder(),
                          )
                        : _buildCircularPlaceholder(),
                  ),
                ),
              );
            }),
            if (remainingCount > 0)
              Positioned(
                left: displayCount * (avatarSize - overlap),
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GymGoColors.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: GymGoColors.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
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

  Widget _buildCircularPlaceholder() {
    return Container(
      color: GymGoColors.surfaceLight,
      child: Icon(
        LucideIcons.user,
        size: avatarSize * 0.5,
        color: GymGoColors.textTertiary,
      ),
    );
  }
}
