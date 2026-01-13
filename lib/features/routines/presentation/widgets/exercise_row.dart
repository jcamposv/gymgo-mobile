import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/exercise_media.dart';
import '../../domain/routine.dart';

/// Row widget displaying an exercise in a routine
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    required this.index,
    this.onTap,
  });

  final ExerciseItem exercise;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GymGoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Row(
        children: [
          // Index number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GymGoColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: GymGoTypography.labelLarge.copyWith(
                  color: GymGoColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Media preview
          _buildMediaPreview(),
          const SizedBox(width: GymGoSpacing.md),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: GymGoTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Sets, reps, weight info
                _buildExerciseDetails(),
              ],
            ),
          ),

          // Chevron
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: GymGoSpacing.sm),
              child: Icon(
                LucideIcons.chevronRight,
                color: GymGoColors.textTertiary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    // Use media resolver to get the best preview image
    final media = ExerciseMediaResolver.resolveMedia(
      gifUrl: exercise.gifUrl,
      videoUrl: exercise.videoUrl,
      thumbnailUrl: exercise.thumbnailUrl,
      preferVideo: false, // Prefer gif for list preview
    );

    if (!media.hasMedia) {
      // Check for YouTube thumbnail
      if (media.isYouTube && media.youtubeVideoId != null) {
        return _buildYoutubeThumbnail(media.youtubeThumbnail!);
      }
      return _buildPlaceholder();
    }

    // For YouTube videos without GIF, show YouTube thumbnail
    if (media.isYouTube && media.url == null) {
      return _buildYoutubeThumbnail(media.youtubeThumbnail!);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: media.url!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (_, __) => _buildPlaceholder(),
            errorWidget: (_, __, ___) => _buildPlaceholder(),
          ),
          // Show play icon overlay if video is available
          if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: const Icon(
                  LucideIcons.play,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYoutubeThumbnail(String thumbnailUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: thumbnailUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (_, __) => _buildPlaceholder(),
            errorWidget: (_, __, ___) => _buildPlaceholder(),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: const Icon(
                LucideIcons.youtube,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Icon(
        LucideIcons.dumbbell,
        size: 24,
        color: GymGoColors.textTertiary,
      ),
    );
  }

  Widget _buildExerciseDetails() {
    final details = <Widget>[];

    // Sets x Reps
    if (exercise.sets != null || exercise.reps != null) {
      details.add(_buildDetailChip(
        icon: LucideIcons.repeat,
        text: exercise.setsRepsDisplay,
      ));
    }

    // Weight
    if (exercise.weight != null && exercise.weight!.isNotEmpty) {
      details.add(_buildDetailChip(
        icon: LucideIcons.scale,
        text: exercise.weight!,
      ));
    }

    // Rest
    if (exercise.restDisplay.isNotEmpty) {
      details.add(_buildDetailChip(
        icon: LucideIcons.clock,
        text: exercise.restDisplay,
      ));
    }

    // Category badge
    if (exercise.category != null && exercise.category!.isNotEmpty) {
      details.add(_buildDetailChip(
        icon: LucideIcons.tag,
        text: exercise.category!,
        color: GymGoColors.info,
      ));
    }

    if (details.isEmpty) {
      return Text(
        'Sin detalles',
        style: GymGoTypography.bodySmall.copyWith(
          color: GymGoColors.textTertiary,
        ),
      );
    }

    return Wrap(
      spacing: GymGoSpacing.sm,
      runSpacing: 4,
      children: details,
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final effectiveColor = color ?? GymGoColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: effectiveColor),
        const SizedBox(width: 3),
        Text(
          text,
          style: GymGoTypography.labelSmall.copyWith(
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}
