import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Screen for managing class templates
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Plantillas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coming soon placeholder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(GymGoSpacing.xl),
                decoration: BoxDecoration(
                  color: GymGoColors.cardBackground,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
                  border: Border.all(color: GymGoColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: GymGoColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.layoutTemplate,
                        size: 40,
                        color: GymGoColors.warning,
                      ),
                    ),
                    const SizedBox(height: GymGoSpacing.lg),
                    Text(
                      'Plantillas de Clases',
                      style: GymGoTypography.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: GymGoSpacing.sm),
                    Text(
                      'Funcionalidad en desarrollo.\nPronto podrás gestionar plantillas de horarios.',
                      style: GymGoTypography.bodyMedium.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: GymGoSpacing.xl),
                    // Feature preview list
                    _buildFeaturePreview(
                      icon: LucideIcons.repeat,
                      label: 'Horarios recurrentes',
                    ),
                    const SizedBox(height: GymGoSpacing.sm),
                    _buildFeaturePreview(
                      icon: LucideIcons.calendarDays,
                      label: 'Generar clases semanales',
                    ),
                    const SizedBox(height: GymGoSpacing.sm),
                    _buildFeaturePreview(
                      icon: LucideIcons.copy,
                      label: 'Duplicar plantillas',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePreview({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: GymGoColors.textTertiary,
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
