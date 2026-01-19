import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';

/// List item widget for displaying a benchmark history entry
class PRHistoryItem extends StatelessWidget {
  const PRHistoryItem({
    super.key,
    required this.benchmark,
    required this.onTap,
  });

  final ExerciseBenchmark benchmark;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getRPEColor(double rpe) {
    if (rpe < 6) return GymGoColors.success;
    if (rpe < 8) return GymGoColors.warning;
    return GymGoColors.error;
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
          border: Border.all(
            color: benchmark.isPr
                ? GymGoColors.primary.withValues(alpha: 0.5)
                : GymGoColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Exercise thumbnail
            _buildThumbnail(),
            const SizedBox(width: GymGoSpacing.md),

            // Info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name + PR badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          benchmark.exercise?.displayName ?? 'Ejercicio',
                          style: GymGoTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (benchmark.isPr) ...[
                        const SizedBox(width: GymGoSpacing.xs),
                        _buildPRBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: GymGoSpacing.xxs),

                  // Date
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 12,
                        color: GymGoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(benchmark.achievedAt),
                        style: GymGoTypography.bodySmall.copyWith(
                          color: GymGoColors.textTertiary,
                        ),
                      ),
                    ],
                  ),

                  // Additional info row (reps, sets, rpe)
                  if (benchmark.reps != null || benchmark.sets != null || benchmark.rpe != null) ...[
                    const SizedBox(height: GymGoSpacing.xs),
                    Wrap(
                      spacing: GymGoSpacing.sm,
                      children: [
                        if (benchmark.reps != null)
                          _buildInfoChip(
                            icon: LucideIcons.repeat,
                            label: '${benchmark.reps} reps',
                          ),
                        if (benchmark.sets != null)
                          _buildInfoChip(
                            icon: LucideIcons.layers,
                            label: '${benchmark.sets} sets',
                          ),
                        if (benchmark.rpe != null)
                          _buildRPEChip(benchmark.rpe!),
                      ],
                    ),
                  ],

                  // Notes
                  if (benchmark.notes != null && benchmark.notes!.isNotEmpty) ...[
                    const SizedBox(height: GymGoSpacing.xs),
                    Text(
                      benchmark.notes!,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Value column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  benchmark.formattedValue,
                  style: GymGoTypography.titleMedium.copyWith(
                    color: benchmark.isPr ? GymGoColors.primary : GymGoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (benchmark.formattedReps != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    benchmark.formattedReps!,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        child: benchmark.exercise?.gifUrl != null
            ? CachedNetworkImage(
                imageUrl: benchmark.exercise!.gifUrl!,
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
        size: 20,
        color: GymGoColors.textTertiary,
      ),
    );
  }

  Widget _buildPRBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.trophy,
            size: 10,
            color: GymGoColors.primary,
          ),
          const SizedBox(width: 2),
          Text(
            'PR',
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: GymGoColors.textTertiary),
        const SizedBox(width: 2),
        Text(
          label,
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRPEChip(double rpe) {
    final color = _getRPEColor(rpe);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.xxs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Text(
        'RPE ${rpe.toStringAsFixed(rpe % 1 == 0 ? 0 : 1)}',
        style: GymGoTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }
}
