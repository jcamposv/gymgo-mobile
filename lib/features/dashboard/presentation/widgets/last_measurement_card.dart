import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';

/// Card showing the last body measurement
class LastMeasurementCard extends StatelessWidget {
  const LastMeasurementCard({
    super.key,
    this.weight,
    this.bodyFat,
    this.muscleMass,
    this.lastMeasuredDate,
    this.weightChange,
    this.isLoading = false,
    this.onTap,
    this.onAddMeasurement,
  });

  final double? weight; // kg
  final double? bodyFat; // percentage
  final double? muscleMass; // kg
  final DateTime? lastMeasuredDate;
  final double? weightChange; // kg difference from previous
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onAddMeasurement;

  bool get hasMeasurement => weight != null || bodyFat != null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (!hasMeasurement) {
      return _buildEmptyState();
    }

    return _buildMeasurementCard();
  }

  Widget _buildLoadingState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Row(
        children: [
          const GymGoShimmerBox(width: 48, height: 48),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                GymGoShimmerBox(width: 100, height: 12),
                SizedBox(height: 8),
                GymGoShimmerBox(width: 80, height: 20),
              ],
            ),
          ),
          const GymGoShimmerBox(width: 40, height: 40),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      onTap: onAddMeasurement,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: GymGoColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: const Icon(
              LucideIcons.ruler,
              color: GymGoColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin mediciones',
                  style: GymGoTypography.titleMedium.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registra tu primera medición',
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GymGoColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: const Icon(
              LucideIcons.plus,
              color: GymGoColors.info,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'ÚLTIMA MEDICIÓN',
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.info,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (lastMeasuredDate != null)
                Text(
                  _formatDate(lastMeasuredDate!),
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Metrics grid
          Row(
            children: [
              if (weight != null)
                Expanded(
                  child: _buildMetricItem(
                    label: 'Peso',
                    value: '${weight!.toStringAsFixed(1)} kg',
                    change: weightChange,
                    icon: LucideIcons.scale,
                  ),
                ),
              if (weight != null && bodyFat != null)
                Container(
                  width: 1,
                  height: 50,
                  color: GymGoColors.cardBorder,
                  margin: const EdgeInsets.symmetric(horizontal: GymGoSpacing.sm),
                ),
              if (bodyFat != null)
                Expanded(
                  child: _buildMetricItem(
                    label: '% Grasa corporal',
                    value: '${bodyFat!.toStringAsFixed(1)}%',
                    icon: LucideIcons.percent,
                  ),
                ),
              if ((weight != null || bodyFat != null) && muscleMass != null)
                Container(
                  width: 1,
                  height: 50,
                  color: GymGoColors.cardBorder,
                  margin: const EdgeInsets.symmetric(horizontal: GymGoSpacing.sm),
                ),
              if (muscleMass != null)
                Expanded(
                  child: _buildMetricItem(
                    label: 'Masa muscular',
                    value: '${muscleMass!.toStringAsFixed(1)} kg',
                    icon: LucideIcons.dumbbell,
                  ),
                ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(LucideIcons.lineChart, size: 16),
                  label: const Text('Ver historial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GymGoColors.textSecondary,
                    side: const BorderSide(color: GymGoColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddMeasurement,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GymGoColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    double? change,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GymGoTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 6),
                _buildChangeIndicator(change),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeIndicator(double change) {
    final isPositive = change > 0;
    final isNeutral = change == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isNeutral
            ? GymGoColors.textTertiary.withValues(alpha: 0.1)
            : isPositive
                ? GymGoColors.error.withValues(alpha: 0.1)
                : GymGoColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNeutral)
            Icon(
              isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              size: 10,
              color: isPositive ? GymGoColors.error : GymGoColors.success,
            ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isNeutral
                  ? GymGoColors.textTertiary
                  : isPositive
                      ? GymGoColors.error
                      : GymGoColors.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';

    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
