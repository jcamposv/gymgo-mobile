import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Progress/Measurements screen placeholder
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Progreso'),
        centerTitle: true,
      ),
      body: _buildPlaceholder(
        icon: LucideIcons.lineChart,
        title: 'Progreso',
        subtitle: 'Próximamente: Registra mediciones y visualiza tu evolución',
        color: GymGoColors.info,
      ),
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusXl),
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xl),
            Text(
              title,
              style: GymGoTypography.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              subtitle,
              style: GymGoTypography.bodyLarge.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.xl),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.lg,
                vertical: GymGoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                border: Border.all(color: GymGoColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.construction,
                    size: 16,
                    color: GymGoColors.warning,
                  ),
                  const SizedBox(width: GymGoSpacing.xs),
                  Text(
                    'En desarrollo',
                    style: GymGoTypography.labelMedium.copyWith(
                      color: GymGoColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
