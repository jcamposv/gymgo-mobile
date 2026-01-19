import 'package:flutter/material.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Reusable empty state widget for benchmarks feature
class BenchmarkEmptyState extends StatelessWidget {
  const BenchmarkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusXl),
              ),
              child: Icon(
                icon,
                size: 40,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),

            // Title
            Text(
              title,
              style: GymGoTypography.headlineSmall.copyWith(
                color: GymGoColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: GymGoSpacing.sm),
              Text(
                subtitle!,
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: GymGoSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.primary,
                  foregroundColor: GymGoColors.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.lg,
                    vertical: GymGoSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: GymGoTypography.buttonMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
