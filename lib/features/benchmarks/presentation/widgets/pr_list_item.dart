import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';

/// List item widget for displaying a current PR
class PRListItem extends StatelessWidget {
  const PRListItem({
    super.key,
    required this.pr,
    required this.onTap,
  });

  final CurrentPR pr;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        decoration: BoxDecoration(
          color: GymGoColors.cardBackground,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          children: [
            // Exercise thumbnail/icon
            _buildThumbnail(),
            const SizedBox(width: GymGoSpacing.md),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    pr.exerciseName,
                    style: GymGoTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: GymGoSpacing.xxs),

                  // Category and date
                  Row(
                    children: [
                      if (pr.exerciseCategory != null) ...[
                        _buildCategoryBadge(),
                        const SizedBox(width: GymGoSpacing.xs),
                      ],
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: GymGoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(pr.achievedAt),
                        style: GymGoTypography.bodySmall.copyWith(
                          color: GymGoColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PR value
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Trophy + value
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.trophy,
                      size: 16,
                      color: GymGoColors.primary,
                    ),
                    const SizedBox(width: GymGoSpacing.xxs),
                    Text(
                      pr.formattedValue,
                      style: GymGoTypography.titleMedium.copyWith(
                        color: GymGoColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Reps if available
                if (pr.formattedReps != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    pr.formattedReps!,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(width: GymGoSpacing.xs),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        child: pr.gifUrl != null && pr.gifUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: pr.gifUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholderIcon(),
                errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        LucideIcons.dumbbell,
        size: 24,
        color: GymGoColors.textTertiary,
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Text(
        pr.exerciseCategory!,
        style: GymGoTypography.labelSmall.copyWith(
          color: GymGoColors.info,
          fontSize: 10,
        ),
      ),
    );
  }
}
