import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Quick action card for Admin Tools screen
class AdminActionCard extends StatelessWidget {
  const AdminActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isLocked = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GymGoColors.cardBackground,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
          border: Border.all(
            color: isLocked
                ? GymGoColors.cardBorder
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? GymGoColors.surface
                          : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isLocked ? GymGoColors.textTertiary : color,
                    ),
                  ),

                  // Title and description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GymGoTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isLocked
                              ? GymGoColors.textTertiary
                              : GymGoColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lock icon overlay
            if (isLocked)
              Positioned(
                top: GymGoSpacing.sm,
                right: GymGoSpacing.sm,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: GymGoColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.lock,
                    size: 12,
                    color: GymGoColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
