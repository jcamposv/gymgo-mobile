import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/rbac/rbac.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';

/// Admin Tools card shown on home dashboard for admin/assistant users
class AdminToolsCard extends StatelessWidget {
  const AdminToolsCard({
    super.key,
    required this.role,
    required this.onTap,
  });

  final AppRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAdmin = adminRoles.contains(role);

    return GestureDetector(
      onTap: onTap,
      child: GymGoCard(
        padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
        child: Row(
          children: [
            // Icon container with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isAdmin
                      ? [
                          GymGoColors.primary,
                          GymGoColors.primary.withValues(alpha: 0.7),
                        ]
                      : [
                          GymGoColors.info,
                          GymGoColors.info.withValues(alpha: 0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              child: Icon(
                isAdmin ? LucideIcons.shield : LucideIcons.wrench,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Herramientas Admin',
                        style: GymGoTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? GymGoColors.primary.withValues(alpha: 0.15)
                              : GymGoColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role.label,
                          style: GymGoTypography.labelSmall.copyWith(
                            color: isAdmin
                                ? GymGoColors.primary
                                : GymGoColors.info,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pagos, clases, plantillas${isAdmin ? ", finanzas" : ""}',
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: GymGoColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
