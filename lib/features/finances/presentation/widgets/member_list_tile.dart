import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/finance_models.dart';

/// A list tile widget for displaying a member in search results
class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    required this.onTap,
    this.showPhone = false,
    this.isSelected = false,
    this.trailing,
  });

  final PaymentMember member;
  final VoidCallback onTap;
  final bool showPhone;
  final bool isSelected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? GymGoColors.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // Avatar
              _MemberAvatar(member: member),
              const SizedBox(width: GymGoSpacing.md),

              // Name and email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full name (bold)
                    Text(
                      member.fullName.isNotEmpty
                          ? member.fullName
                          : 'Sin nombre',
                      style: GymGoTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? GymGoColors.primary
                            : GymGoColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Email (small, gray)
                    Text(
                      member.email.isNotEmpty ? member.email : 'Sin email',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Phone (optional, small, gray)
                    if (showPhone &&
                        member.phone != null &&
                        member.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.phone,
                            size: 10,
                            color: GymGoColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            member.phone!,
                            style: GymGoTypography.labelSmall.copyWith(
                              color: GymGoColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge or trailing widget
              if (trailing != null)
                trailing!
              else if (member.status != null) ...[
                const SizedBox(width: GymGoSpacing.sm),
                _StatusBadge(status: member.status!),
              ],

              // Selection indicator
              if (isSelected) ...[
                const SizedBox(width: GymGoSpacing.sm),
                Icon(
                  LucideIcons.checkCircle2,
                  size: 20,
                  color: GymGoColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Member avatar with initials fallback
class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final PaymentMember member;

  @override
  Widget build(BuildContext context) {
    if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(member.avatarUrl!),
        backgroundColor: GymGoColors.surface,
        onBackgroundImageError: (_, __) {},
      );
    }

    // Fallback to initials
    return CircleAvatar(
      radius: 22,
      backgroundColor: GymGoColors.primary.withValues(alpha: 0.15),
      child: Text(
        member.initials,
        style: GymGoTypography.labelMedium.copyWith(
          color: GymGoColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GymGoTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return GymGoColors.success;
      case 'inactive':
        return GymGoColors.textTertiary;
      case 'suspended':
        return GymGoColors.warning;
      case 'cancelled':
        return GymGoColors.error;
      default:
        return GymGoColors.textTertiary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Activo';
      case 'inactive':
        return 'Inactivo';
      case 'suspended':
        return 'Suspendido';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

/// Compact member chip for showing selected member
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.member,
    this.onTap,
    this.onRemove,
  });

  final PaymentMember member;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(GymGoSpacing.sm),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          children: [
            // Small avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: GymGoColors.primary.withValues(alpha: 0.15),
              backgroundImage: member.avatarUrl != null &&
                      member.avatarUrl!.isNotEmpty
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                  ? Text(
                      member.initials,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: GymGoSpacing.sm),

            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    member.fullName,
                    style: GymGoTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    member.email,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Change button or remove
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(LucideIcons.x),
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                color: GymGoColors.textTertiary,
              )
            else if (onTap != null) ...[
              const SizedBox(width: GymGoSpacing.xs),
              Text(
                'Cambiar',
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: GymGoColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
