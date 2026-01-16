import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/rbac/rbac.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/providers/role_providers.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../classes/presentation/providers/templates_providers.dart';
import '../../../classes/presentation/widgets/generate_classes_sheet.dart';
import '../widgets/admin_action_card.dart';

/// Admin Tools screen with quick action cards
/// Only accessible to ADMIN and ASSISTANT roles
class AdminToolsScreen extends ConsumerWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Herramientas Admin'),
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
              const SizedBox(height: GymGoSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null || !profile.canAccessAdminTools) {
            return _buildAccessDenied(context);
          }
          return _buildContent(context, ref, profile);
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
              'No tienes permisos para acceder a las herramientas de administración.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.xl),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    final isAdmin = profile.isAdmin;
    final role = profile.role;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role badge
            _buildRoleBadge(role),
            const SizedBox(height: GymGoSpacing.lg),

            // Quick Actions section
            Text(
              'Acciones rápidas',
              style: GymGoTypography.labelMedium.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),

            // Grid of action cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: GymGoSpacing.md,
              crossAxisSpacing: GymGoSpacing.md,
              childAspectRatio: 1.1,
              children: [
                // Register Payment
                AdminActionCard(
                  icon: LucideIcons.receipt,
                  title: 'Registrar\nPago',
                  description: 'Cobrar a clientes',
                  color: GymGoColors.success,
                  onTap: () => context.push(Routes.adminRegisterPayment),
                ),

                // Create Class
                AdminActionCard(
                  icon: LucideIcons.calendarPlus,
                  title: 'Crear\nClase',
                  description: 'Programar sesión',
                  color: GymGoColors.info,
                  onTap: () => context.push(Routes.adminCreateClass),
                ),

                // Generate Classes - NEW
                AdminActionCard(
                  icon: LucideIcons.sparkles,
                  title: 'Generar\nClases',
                  description: 'Desde plantillas',
                  color: const Color(0xFF9333EA), // Purple
                  onTap: () => _showGenerateClasses(context, ref),
                ),

                // Templates
                AdminActionCard(
                  icon: LucideIcons.layoutTemplate,
                  title: 'Plantillas',
                  description: 'Gestionar horarios',
                  color: GymGoColors.warning,
                  onTap: () => context.push(Routes.adminTemplates),
                ),

                // Finance Summary (ADMIN only)
                if (isAdmin)
                  AdminActionCard(
                    icon: LucideIcons.barChart3,
                    title: 'Resumen\nFinanzas',
                    description: 'Ver ingresos',
                    color: GymGoColors.primary,
                    onTap: () => context.push(Routes.adminFinances),
                  )
                else
                  AdminActionCard(
                    icon: LucideIcons.barChart3,
                    title: 'Resumen\nFinanzas',
                    description: 'Solo admin',
                    color: GymGoColors.textTertiary,
                    isLocked: true,
                    onTap: () => _showLockedFeatureMessage(context),
                  ),
              ],
            ),

            const SizedBox(height: GymGoSpacing.xl),

            // Additional tools section
            Text(
              'Más herramientas',
              style: GymGoTypography.labelMedium.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),

            // List of additional tools
            GymGoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolListItem(
                    icon: LucideIcons.users,
                    label: 'Ver miembros',
                    description: 'Lista de clientes',
                    onTap: () => context.push(Routes.adminMembers),
                  ),
                  const Divider(height: 1, color: GymGoColors.cardBorder),
                  _buildToolListItem(
                    icon: LucideIcons.calendar,
                    label: 'Ver clases',
                    description: 'Agenda completa',
                    // Use go() to navigate to ShellRoute pages to avoid duplicate key issues
                    onTap: () => context.go(Routes.memberClasses),
                  ),
                  const Divider(height: 1, color: GymGoColors.cardBorder),
                  _buildToolListItem(
                    icon: LucideIcons.clipboardCheck,
                    label: 'Check-in manual',
                    description: 'Registrar asistencia',
                    onTap: () => context.push(Routes.adminCheckIn),
                  ),
                  const Divider(height: 1, color: GymGoColors.cardBorder),
                  _buildToolListItem(
                    icon: LucideIcons.sliders,
                    label: 'Límites de reserva',
                    description: 'Max clases por día',
                    onTap: () => context.push(Routes.adminBookingLimits),
                  ),
                ],
              ),
            ),

            const SizedBox(height: GymGoSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(AppRole role) {
    final isAdmin = adminRoles.contains(role);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.md,
        vertical: GymGoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isAdmin
            ? GymGoColors.primary.withValues(alpha: 0.1)
            : GymGoColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: isAdmin
              ? GymGoColors.primary.withValues(alpha: 0.3)
              : GymGoColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? LucideIcons.shield : LucideIcons.userCog,
            size: 16,
            color: isAdmin ? GymGoColors.primary : GymGoColors.info,
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Text(
            role.label,
            style: GymGoTypography.labelMedium.copyWith(
              color: isAdmin ? GymGoColors.primary : GymGoColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolListItem({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GymGoTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedFeatureMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta función solo está disponible para administradores'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showGenerateClasses(BuildContext context, WidgetRef ref) async {
    final result = await GenerateClassesSheet.show(context);

    if (result != null && result.success && context.mounted) {
      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();

      // Build message with errors if any
      String message = result.message;
      if (result.hasErrors) {
        message += '\n(${result.errors.length} advertencias)';
      }

      // Show single success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: GymGoColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(GymGoSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
        ),
      );

      // Refresh templates
      ref.invalidate(templatesProvider);
    }
  }
}
