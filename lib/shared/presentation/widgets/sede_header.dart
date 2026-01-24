import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';
import '../../providers/location_providers.dart';
import 'location_switcher.dart';

/// Header widget showing current sede with switcher button
/// Used in admin tools screens to show location context
class SedeHeader extends ConsumerWidget {
  const SedeHeader({
    super.key,
    this.showSwitcherButton = true,
  });

  /// Whether to show the switcher button (dropdown arrow)
  final bool showSwitcherButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(adminActiveLocationProvider);
    final hasMultiple = ref.watch(hasMultipleLocationsProvider);
    final canSwitch = ref.watch(canSwitchLocationProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.md,
        vertical: GymGoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: GymGoColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: locationAsync.when(
        data: (location) {
          if (location == null) {
            return _buildNoLocation();
          }

          return InkWell(
            onTap: (showSwitcherButton && canSwitch)
                ? () => LocationSwitcher.show(context)
                : null,
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            child: Row(
              children: [
                // Location icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GymGoColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: GymGoColors.primary,
                  ),
                ),
                const SizedBox(width: GymGoSpacing.sm),

                // Location info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sede actual',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.primary.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              location.name,
                              style: GymGoTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: GymGoColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (location.isPrimary) ...[
                            const SizedBox(width: GymGoSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: GymGoColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Principal',
                                style: GymGoTypography.labelSmall.copyWith(
                                  color: GymGoColors.primary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Switcher button
                if (showSwitcherButton && canSwitch) ...[
                  const SizedBox(width: GymGoSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: GymGoColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cambiar',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: GymGoColors.primary,
                        ),
                      ],
                    ),
                  ),
                ] else if (hasMultiple) ...[
                  // Show location count if multiple but can't switch
                  const SizedBox(width: GymGoSpacing.sm),
                  Consumer(
                    builder: (context, ref, _) {
                      final locationsAsync =
                          ref.watch(organizationLocationsProvider);
                      final count = locationsAsync.valueOrNull?.length ?? 0;
                      if (count <= 1) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GymGoColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$count sedes',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => _buildLoading(),
        error: (_, __) => _buildError(),
      ),
    );
  }

  Widget _buildNoLocation() {
    return Row(
      children: [
        const Icon(
          LucideIcons.alertCircle,
          size: 16,
          color: GymGoColors.warning,
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          'Sin sede asignada',
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: GymGoColors.primary,
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          'Cargando sede...',
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Row(
      children: [
        const Icon(
          LucideIcons.alertCircle,
          size: 16,
          color: GymGoColors.error,
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          'Error al cargar sede',
          style: GymGoTypography.bodySmall.copyWith(
            color: GymGoColors.error,
          ),
        ),
      ],
    );
  }
}

/// Compact version of SedeHeader for use in app bars
class SedeHeaderCompact extends ConsumerWidget {
  const SedeHeaderCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(adminActiveLocationProvider);
    final canSwitch = ref.watch(canSwitchLocationProvider);

    return locationAsync.when(
      data: (location) {
        if (location == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: canSwitch ? () => LocationSwitcher.show(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: GymGoColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 12,
                  color: GymGoColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  location.name,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (canSwitch) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 12,
                    color: GymGoColors.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
