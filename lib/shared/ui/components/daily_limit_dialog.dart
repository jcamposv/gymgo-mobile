import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';
import '../../../features/classes/domain/booking_limit.dart';
import 'gymgo_primary_button.dart';

/// Dialog shown when daily class booking limit is reached.
///
/// WEB Contract Reference:
/// - Title: "Límite diario alcanzado"
/// - Body: "Ya alcanzaste el máximo de {limit} clases para hoy."
/// - Actions: "Ver mis reservas", "OK" / "Cerrar"
/// - Staff override: NOT implemented in WEB UI, so not in mobile
class DailyLimitDialog extends StatelessWidget {
  const DailyLimitDialog({
    super.key,
    required this.exception,
    this.onViewReservations,
    this.onClose,
    this.isStaffView = false,
  });

  /// The exception containing limit details
  final DailyClassLimitException exception;

  /// Callback when "Ver mis reservas" is tapped
  final VoidCallback? onViewReservations;

  /// Callback when dialog is closed
  final VoidCallback? onClose;

  /// Whether this is shown in staff context (for a member)
  final bool isStaffView;

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    required DailyClassLimitException exception,
    VoidCallback? onViewReservations,
    bool isStaffView = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DailyLimitDialog(
        exception: exception,
        onViewReservations: onViewReservations,
        onClose: () => Navigator.of(context).pop(),
        isStaffView: isStaffView,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GymGoColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        side: const BorderSide(color: GymGoColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GymGoColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                size: 32,
                color: GymGoColors.warning,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),

            // Title
            Text(
              'Límite diario alcanzado',
              style: GymGoTypography.headlineSmall.copyWith(
                color: GymGoColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),

            // Message
            Text(
              isStaffView
                  ? 'El miembro ya tiene ${exception.currentCount} de ${exception.limit} clases para el ${exception.targetDate}'
                  : 'Ya alcanzaste el máximo de ${exception.limit} clases para hoy.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),

            // Detail info
            Container(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: GymGoColors.textTertiary,
                  ),
                  const SizedBox(width: GymGoSpacing.xs),
                  Text(
                    '${exception.currentCount} de ${exception.limit} clases',
                    style: GymGoTypography.labelMedium.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Existing bookings list (if available)
            if (exception.existingBookings.isNotEmpty) ...[
              const SizedBox(height: GymGoSpacing.md),
              _buildExistingBookingsList(),
            ],

            const SizedBox(height: GymGoSpacing.xl),

            // Actions
            if (onViewReservations != null) ...[
              GymGoPrimaryButton(
                text: isStaffView ? 'Ver reservas del miembro' : 'Ver mis reservas',
                onPressed: () {
                  Navigator.of(context).pop();
                  onViewReservations?.call();
                },
              ),
              const SizedBox(height: GymGoSpacing.sm),
            ],

            GymGoSecondaryButton(
              text: 'Cerrar',
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingBookingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isStaffView ? 'Reservas del miembro hoy:' : 'Tus reservas de hoy:',
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.textTertiary,
          ),
        ),
        const SizedBox(height: GymGoSpacing.xs),
        ...exception.existingBookings.take(3).map((booking) => Padding(
              padding: const EdgeInsets.only(bottom: GymGoSpacing.xxs),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    size: 14,
                    color: GymGoColors.success,
                  ),
                  const SizedBox(width: GymGoSpacing.xs),
                  Expanded(
                    child: Text(
                      booking.className,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTime(booking.startTime),
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )),
        if (exception.existingBookings.length > 3)
          Text(
            '+${exception.existingBookings.length - 3} más',
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
      ],
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

/// Helper extension to show daily limit dialog from exception
extension DailyLimitDialogExtension on BuildContext {
  /// Show daily limit reached dialog
  Future<void> showDailyLimitDialog(
    DailyClassLimitException exception, {
    VoidCallback? onViewReservations,
    bool isStaffView = false,
  }) {
    return DailyLimitDialog.show(
      this,
      exception: exception,
      onViewReservations: onViewReservations,
      isStaffView: isStaffView,
    );
  }
}
