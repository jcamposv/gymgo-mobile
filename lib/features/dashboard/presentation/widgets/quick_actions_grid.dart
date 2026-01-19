import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Quick action item data
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? badge;
}

/// Grid of quick action buttons
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
  });

  final List<QuickAction> actions;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.screenHorizontal,
          ),
          child: Text(
            'Accesos rápidos',
            style: GymGoTypography.titleMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: GymGoSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.screenHorizontal,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((action) {
              return Expanded(
                child: _QuickActionItem(action: action),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? GymGoColors.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        action.onTap();
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  action.icon,
                  color: color,
                  size: 24,
                ),
              ),
              if (action.badge != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: GymGoColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      action.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            action.label,
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Default quick actions for GymGo
class GymGoQuickActions {
  GymGoQuickActions._();

  static QuickAction reserveClass(VoidCallback onTap) {
    return QuickAction(
      icon: LucideIcons.calendarPlus,
      label: 'Reservar',
      onTap: onTap,
      color: GymGoColors.primary,
    );
  }

  static QuickAction myClasses(VoidCallback onTap, {String? badge}) {
    return QuickAction(
      icon: LucideIcons.calendarCheck,
      label: 'Mis clases',
      onTap: onTap,
      color: GymGoColors.success,
      badge: badge,
    );
  }

  static QuickAction myWorkouts(VoidCallback onTap) {
    return QuickAction(
      icon: LucideIcons.listChecks,
      label: 'Rutinas',
      onTap: onTap,
      color: GymGoColors.warning,
    );
  }

  static QuickAction addMeasurement(VoidCallback onTap) {
    return QuickAction(
      icon: LucideIcons.ruler,
      label: 'Medición',
      onTap: onTap,
      color: GymGoColors.info,
    );
  }

  static QuickAction progress(VoidCallback onTap) {
    return QuickAction(
      icon: LucideIcons.lineChart,
      label: 'Progreso',
      onTap: onTap,
      color: GymGoColors.info,
    );
  }

  static QuickAction history(VoidCallback onTap) {
    return QuickAction(
      icon: LucideIcons.history,
      label: 'Historial',
      onTap: onTap,
      color: GymGoColors.textSecondary,
    );
  }

  static QuickAction benchmarks(VoidCallback onTap) {
    return QuickAction(
      icon: LucideIcons.trophy,
      label: 'PRs',
      onTap: onTap,
      color: GymGoColors.warning,
    );
  }
}
