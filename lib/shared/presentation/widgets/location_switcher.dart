import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';
import '../../domain/location.dart';
import '../../providers/location_providers.dart';

/// Bottom sheet for switching between locations (admin only)
class LocationSwitcher extends ConsumerWidget {
  const LocationSwitcher({super.key});

  /// Show the location switcher bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: GymGoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      builder: (context) => const LocationSwitcher(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(organizationLocationsProvider);
    final activeLocationId = ref.watch(adminActiveLocationIdProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.screenHorizontal,
          vertical: GymGoSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GymGoColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),

            // Title
            Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 20,
                  color: GymGoColors.primary,
                ),
                const SizedBox(width: GymGoSpacing.sm),
                Text(
                  'Seleccionar Sede',
                  style: GymGoTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GymGoSpacing.xs),
            Text(
              'Los datos mostrados se filtrarán por la sede seleccionada',
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),

            // Locations list
            locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return _buildEmptyState();
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: locations.map((location) {
                    final isSelected = activeLocationId == location.id ||
                        (activeLocationId == null && location.isPrimary);

                    return _LocationTile(
                      location: location,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(adminActiveLocationIdProvider.notifier).state =
                            location.id;
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(GymGoSpacing.xl),
                  child: CircularProgressIndicator(
                    color: GymGoColors.primary,
                  ),
                ),
              ),
              error: (_, __) => _buildErrorState(),
            ),

            const SizedBox(height: GymGoSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.xl),
      child: Column(
        children: [
          const Icon(
            LucideIcons.building2,
            size: 48,
            color: GymGoColors.textTertiary,
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'No hay sedes configuradas',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.xl),
      child: Column(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: GymGoColors.error,
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Error al cargar las sedes',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual location tile in the switcher
class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final Location location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
      child: Material(
        color: isSelected
            ? GymGoColors.primary.withValues(alpha: 0.1)
            : GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? GymGoColors.primary
                    : GymGoColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Location icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? GymGoColors.primary.withValues(alpha: 0.15)
                        : GymGoColors.surface,
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                  child: Icon(
                    LucideIcons.building2,
                    size: 20,
                    color: isSelected
                        ? GymGoColors.primary
                        : GymGoColors.textTertiary,
                  ),
                ),
                const SizedBox(width: GymGoSpacing.md),

                // Location info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.name,
                              style: GymGoTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? GymGoColors.primary
                                    : GymGoColors.textPrimary,
                              ),
                            ),
                          ),
                          if (location.isPrimary) ...[
                            const SizedBox(width: GymGoSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: GymGoSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: GymGoColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Principal',
                                style: GymGoTypography.labelSmall.copyWith(
                                  color: GymGoColors.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (location.shortAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          location.shortAddress!,
                          style: GymGoTypography.bodySmall.copyWith(
                            color: GymGoColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Check icon
                if (isSelected)
                  const Icon(
                    LucideIcons.check,
                    size: 20,
                    color: GymGoColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
