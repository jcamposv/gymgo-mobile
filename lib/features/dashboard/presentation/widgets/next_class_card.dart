import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';

/// Card showing the next scheduled class
class NextClassCard extends StatelessWidget {
  const NextClassCard({
    super.key,
    this.className,
    this.instructorName,
    this.dateTime,
    this.duration,
    this.spotsAvailable,
    this.isLoading = false,
    this.onTap,
    this.onCancel,
    this.onReserve,
  });

  final String? className;
  final String? instructorName;
  final DateTime? dateTime;
  final int? duration; // in minutes
  final int? spotsAvailable;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReserve;

  bool get hasClass => className != null && dateTime != null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (!hasClass) {
      return _buildEmptyState();
    }

    return _buildClassCard();
  }

  Widget _buildLoadingState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GymGoShimmerBox(width: 48, height: 48),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    GymGoShimmerBox(width: 120, height: 16),
                    SizedBox(height: 8),
                    GymGoShimmerBox(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.md),
          const GymGoShimmerBox(height: 44),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      onTap: onReserve,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: GymGoColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: const Icon(
              LucideIcons.calendarPlus,
              color: GymGoColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Sin clases reservadas',
            style: GymGoTypography.titleMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xxs),
          Text(
            'Explora las clases disponibles',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReserve,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Reservar clase'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GymGoColors.primary,
                side: BorderSide(
                  color: GymGoColors.primary.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and badge
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: GymGoColors.primaryGradient,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                ),
                child: const Icon(
                  LucideIcons.users,
                  color: GymGoColors.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PRÓXIMA CLASE',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        _buildTimeBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      className!,
                      style: GymGoTypography.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Class details
          Container(
            padding: const EdgeInsets.all(GymGoSpacing.sm),
            decoration: BoxDecoration(
              color: GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Row(
              children: [
                _buildDetailItem(
                  icon: LucideIcons.clock,
                  text: _formatTime(dateTime!),
                ),
                const SizedBox(width: GymGoSpacing.lg),
                if (duration != null)
                  _buildDetailItem(
                    icon: LucideIcons.timer,
                    text: '$duration min',
                  ),
                const SizedBox(width: GymGoSpacing.lg),
                if (instructorName != null)
                  Expanded(
                    child: _buildDetailItem(
                      icon: LucideIcons.userCircle,
                      text: instructorName!,
                      flex: true,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GymGoColors.textSecondary,
                    side: const BorderSide(color: GymGoColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.eye, size: 18),
                  label: const Text('Ver detalles'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBadge() {
    final isToday = _isToday(dateTime!);
    final isTomorrow = _isTomorrow(dateTime!);

    String label;
    Color bgColor;

    if (isToday) {
      label = 'Hoy';
      bgColor = GymGoColors.success;
    } else if (isTomorrow) {
      label = 'Mañana';
      bgColor = GymGoColors.warning;
    } else {
      label = _formatDate(dateTime!);
      bgColor = GymGoColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: GymGoTypography.labelSmall.copyWith(
          color: bgColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
    bool flex = false,
  }) {
    final content = Row(
      mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: GymGoColors.textTertiary,
        ),
        const SizedBox(width: 6),
        flex
            ? Expanded(
                child: Text(
                  text,
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                text,
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
      ],
    );
    return content;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isTomorrow(DateTime dt) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
  }
}
