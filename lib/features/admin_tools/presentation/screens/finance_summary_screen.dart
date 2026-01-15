import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/rbac/rbac.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/providers/role_providers.dart';

/// Finance summary screen (ADMIN only)
class FinanceSummaryScreen extends ConsumerWidget {
  const FinanceSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Resumen Finanzas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: GymGoColors.error,
              ),
              const SizedBox(height: GymGoSpacing.md),
              Text(
                'Error al cargar permisos',
                style: GymGoTypography.bodyLarge.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        data: (profile) {
          // Check if user has admin permission to view finances
          final canView = profile?.hasPermission(AppPermission.viewGymFinances) ?? false;

          if (!canView) {
            return _buildAccessDenied(context);
          }

          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GymGoColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldOff,
                size: 40,
                color: GymGoColors.error,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Acceso restringido',
              style: GymGoTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'Solo los administradores pueden ver el resumen de finanzas.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.xl),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
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
                      color: GymGoColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.barChart3,
                      size: 40,
                      color: GymGoColors.primary,
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.lg),
                  Text(
                    'Resumen Financiero',
                    style: GymGoTypography.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GymGoSpacing.sm),
                  Text(
                    'Funcionalidad en desarrollo.\nPronto podrás ver el resumen de ingresos.',
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GymGoSpacing.xl),
                  // Feature preview list
                  _buildFeaturePreview(
                    icon: LucideIcons.trendingUp,
                    label: 'Ingresos del mes',
                  ),
                  const SizedBox(height: GymGoSpacing.sm),
                  _buildFeaturePreview(
                    icon: LucideIcons.trendingDown,
                    label: 'Gastos del mes',
                  ),
                  const SizedBox(height: GymGoSpacing.sm),
                  _buildFeaturePreview(
                    icon: LucideIcons.pieChart,
                    label: 'Distribución por tipo',
                  ),
                  const SizedBox(height: GymGoSpacing.sm),
                  _buildFeaturePreview(
                    icon: LucideIcons.calendar,
                    label: 'Filtrar por período',
                  ),
                ],
              ),
            ),
          ],
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
