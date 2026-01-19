import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';

/// Card widget for benchmark category in grid menu
class BenchmarkCategoryCard extends StatelessWidget {
  const BenchmarkCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final BenchmarkCategory category;
  final VoidCallback onTap;

  IconData _getCategoryIcon() {
    switch (category.id) {
      case 'prs':
        return LucideIcons.trophy;
      case 'cardio':
        return LucideIcons.heartPulse;
      case 'flexibility':
        return LucideIcons.move;
      default:
        return LucideIcons.target;
    }
  }

  Color _getCategoryColor() {
    switch (category.id) {
      case 'prs':
        return GymGoColors.primary;
      case 'cardio':
        return GymGoColors.error;
      case 'flexibility':
        return GymGoColors.info;
      default:
        return GymGoColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: GymGoColors.cardBackground,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
          border: Border.all(color: GymGoColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: color,
                      size: 24,
                    ),
                  ),

                  // Title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: GymGoTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: GymGoColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.subtitle != null) ...[
                        const SizedBox(height: GymGoSpacing.xxs),
                        Text(
                          category.subtitle!,
                          style: GymGoTypography.bodySmall.copyWith(
                            color: GymGoColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Positioned(
              top: GymGoSpacing.md,
              right: GymGoSpacing.md,
              child: Icon(
                LucideIcons.chevronRight,
                color: GymGoColors.textTertiary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
