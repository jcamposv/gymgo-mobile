import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Help Center placeholder screen
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Centro de ayuda'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: GymGoColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    LucideIcons.construction,
                    color: GymGoColors.primary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: GymGoSpacing.lg),
                Text(
                  'Próximamente',
                  style: GymGoTypography.headlineSmall,
                ),
                const SizedBox(height: GymGoSpacing.sm),
                Text(
                  'Estamos trabajando en el centro de ayuda.\nMuy pronto tendrás acceso a guías y preguntas frecuentes.',
                  style: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
