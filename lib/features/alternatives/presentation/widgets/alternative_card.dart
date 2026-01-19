import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/exercise_alternative.dart';

/// Card widget displaying an exercise alternative
class AlternativeCard extends StatelessWidget {
  const AlternativeCard({
    super.key,
    required this.alternative,
    this.onTap,
  });

  final ExerciseAlternative alternative;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final exercise = alternative.exercise;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        decoration: BoxDecoration(
          color: GymGoColors.surfaceLight,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(
            color: GymGoColors.cardBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GIF preview
            _buildGifPreview(exercise.gifUrl),

            const SizedBox(width: GymGoSpacing.md),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + score
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.displayName,
                          style: GymGoTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.sm),
                      _buildScoreBadge(),
                    ],
                  ),

                  const SizedBox(height: GymGoSpacing.xs),

                  // Reason
                  Text(
                    alternative.reason,
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: GymGoSpacing.sm),

                  // Tags
                  _buildTags(exercise),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifPreview(String? gifUrl) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        child: gifUrl != null && gifUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: gifUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: GymGoColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        LucideIcons.dumbbell,
        size: 24,
        color: GymGoColors.textTertiary,
      ),
    );
  }

  Widget _buildScoreBadge() {
    final score = alternative.score;
    final color = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.sparkles,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$score',
            style: GymGoTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags(AlternativeExercise exercise) {
    return Wrap(
      spacing: GymGoSpacing.xs,
      runSpacing: GymGoSpacing.xs,
      children: [
        if (exercise.difficulty != null)
          _buildTag(
            exercise.difficulty!,
            _getDifficultyColor(exercise.difficulty!),
          ),
        if (exercise.category != null)
          _buildTag(
            exercise.category!,
            GymGoColors.info,
          ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Text(
        text,
        style: GymGoTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return GymGoColors.success;
    if (score >= 60) return GymGoColors.primary;
    if (score >= 40) return GymGoColors.warning;
    return GymGoColors.textSecondary;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return GymGoColors.success;
      case 'intermedio':
      case 'intermediate':
        return GymGoColors.warning;
      case 'avanzado':
      case 'advanced':
        return GymGoColors.error;
      default:
        return GymGoColors.textSecondary;
    }
  }
}
