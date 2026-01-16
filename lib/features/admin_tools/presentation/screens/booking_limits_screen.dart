import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/data/organization_settings_repository.dart';
import '../../../../shared/domain/organization_settings.dart';
import '../../../../shared/ui/components/components.dart';

/// Provider for organization settings repository
final _settingsRepositoryProvider = Provider<OrganizationSettingsRepository>((ref) {
  return OrganizationSettingsRepository(Supabase.instance.client);
});

/// Provider for booking limits
final _bookingLimitsProvider = FutureProvider<OrganizationBookingLimits>((ref) async {
  final repository = ref.watch(_settingsRepositoryProvider);
  return repository.getBookingLimits(forceRefresh: true);
});

/// Booking limits configuration screen for Admin Tools.
///
/// WEB Contract Reference:
/// - Field: max_classes_per_day (1-10, NULL = unlimited)
/// - Options: Ilimitado, 1-5 clases por día
/// - Table: organizations
class BookingLimitsScreen extends ConsumerStatefulWidget {
  const BookingLimitsScreen({super.key});

  @override
  ConsumerState<BookingLimitsScreen> createState() => _BookingLimitsScreenState();
}

class _BookingLimitsScreenState extends ConsumerState<BookingLimitsScreen> {
  int? _selectedLimit;
  bool _isLoading = false;
  bool _hasChanges = false;

  /// Limit options matching WEB contract
  static const List<_LimitOption> _limitOptions = [
    _LimitOption(
      value: null,
      label: 'Ilimitado',
      description: 'Sin restricción de clases por día',
    ),
    _LimitOption(
      value: 1,
      label: '1 clase por día',
      description: 'Máximo 1 clase por miembro por día',
    ),
    _LimitOption(
      value: 2,
      label: '2 clases por día',
      description: 'Máximo 2 clases por miembro por día',
    ),
    _LimitOption(
      value: 3,
      label: '3 clases por día',
      description: 'Máximo 3 clases por miembro por día',
    ),
    _LimitOption(
      value: 4,
      label: '4 clases por día',
      description: 'Máximo 4 clases por miembro por día',
    ),
    _LimitOption(
      value: 5,
      label: '5 clases por día',
      description: 'Máximo 5 clases por miembro por día',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(_bookingLimitsProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Límites de Reserva'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (settings) => _buildContent(settings),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
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
              'Error al cargar configuración',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error,
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(_bookingLimitsProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.primary,
                foregroundColor: GymGoColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OrganizationBookingLimits settings) {
    // Initialize selected limit from settings on first build
    _selectedLimit ??= settings.maxClassesPerDay;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            GymGoCard(
              backgroundColor: GymGoColors.info.withValues(alpha: 0.1),
              borderColor: GymGoColors.info.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 20,
                    color: GymGoColors.info,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Expanded(
                    child: Text(
                      'Limita cuántas clases puede reservar un miembro en un mismo día.',
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),

            // Section title
            Text(
              'Máximo de clases por día',
              style: GymGoTypography.labelLarge.copyWith(
                color: GymGoColors.textPrimary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            Text(
              'Este límite aplica a reservas confirmadas y lista de espera.',
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),

            // Options list
            GymGoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: _limitOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedLimit == option.value;
                  final isLast = index == _limitOptions.length - 1;

                  return Column(
                    children: [
                      _buildOptionTile(option, isSelected),
                      if (!isLast)
                        const Divider(height: 1, color: GymGoColors.cardBorder),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: GymGoSpacing.lg),

            // Timezone info
            Container(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: GymGoColors.textTertiary,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Expanded(
                    child: Text(
                      'El día se calcula según la zona horaria: ${settings.timezone}',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: GymGoSpacing.xl),

            // Save button
            GymGoPrimaryButton(
              text: 'Guardar cambios',
              isLoading: _isLoading,
              isEnabled: _hasChanges,
              onPressed: _hasChanges ? () => _saveChanges(settings) : null,
            ),

            const SizedBox(height: GymGoSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(_LimitOption option, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLimit = option.value;
          _hasChanges = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? GymGoColors.primary : GymGoColors.inputBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: GymGoColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: GymGoSpacing.md),
            // Label and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: GymGoTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? GymGoColors.textPrimary : GymGoColors.textSecondary,
                    ),
                  ),
                  Text(
                    option.description,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Check icon for selected
            if (isSelected)
              const Icon(
                LucideIcons.check,
                size: 20,
                color: GymGoColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(OrganizationBookingLimits currentSettings) async {
    setState(() => _isLoading = true);

    try {
      // Update organization settings in Supabase
      await Supabase.instance.client
          .from('organizations')
          .update({'max_classes_per_day': _selectedLimit})
          .eq('id', currentSettings.organizationId);

      // Clear cache
      ref.read(_settingsRepositoryProvider).clearCache();

      // Refresh data
      ref.invalidate(_bookingLimitsProvider);

      if (mounted) {
        GymGoToast.success(context, 'Configuración guardada');
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        GymGoToast.error(context, 'Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Helper class for limit options
class _LimitOption {
  const _LimitOption({
    required this.value,
    required this.label,
    required this.description,
  });

  final int? value;
  final String label;
  final String description;
}
