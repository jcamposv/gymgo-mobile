import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/finance_models.dart';

/// Finance overview card showing KPIs
class FinanceOverviewCard extends StatelessWidget {
  const FinanceOverviewCard({super.key, required this.overview});

  final FinanceOverview overview;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period indicator
        Text(
          'Período: ${dateFormat.format(overview.periodFrom)} - ${dateFormat.format(overview.periodTo)}',
          style: GymGoTypography.labelMedium.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
        const SizedBox(height: GymGoSpacing.md),

        // Net Profit Card (Main KPI)
        GymGoCard(
          padding: const EdgeInsets.all(GymGoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: overview.netProfit >= 0
                          ? GymGoColors.success.withValues(alpha: 0.15)
                          : GymGoColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    ),
                    child: Icon(
                      overview.netProfit >= 0
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      color: overview.netProfit >= 0
                          ? GymGoColors.success
                          : GymGoColors.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: GymGoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ganancia Neta',
                          style: GymGoTypography.bodyMedium.copyWith(
                            color: GymGoColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(overview.netProfit),
                          style: GymGoTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: overview.netProfit >= 0
                                ? GymGoColors.success
                                : GymGoColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: GymGoSpacing.md),

        // Income / Expenses row
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Ingresos Totales',
                amount: currencyFormat.format(overview.totalIncome),
                icon: LucideIcons.arrowDownCircle,
                color: GymGoColors.success,
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              child: _SummaryCard(
                title: 'Gastos Totales',
                amount: currencyFormat.format(overview.totalExpenses),
                icon: LucideIcons.arrowUpCircle,
                color: GymGoColors.error,
              ),
            ),
          ],
        ),

        const SizedBox(height: GymGoSpacing.md),

        // Income breakdown
        GymGoCard(
          padding: const EdgeInsets.all(GymGoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Desglose de Ingresos',
                style: GymGoTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: GymGoSpacing.md),
              _BreakdownRow(
                label: 'Membresías',
                amount: currencyFormat.format(overview.membershipIncome),
                icon: LucideIcons.creditCard,
                percentage: overview.totalIncome > 0
                    ? (overview.membershipIncome / overview.totalIncome * 100)
                    : 0,
              ),
              const Divider(height: GymGoSpacing.md),
              _BreakdownRow(
                label: 'Otros ingresos',
                amount: currencyFormat.format(overview.otherIncome),
                icon: LucideIcons.coins,
                percentage: overview.totalIncome > 0
                    ? (overview.otherIncome / overview.totalIncome * 100)
                    : 0,
              ),
            ],
          ),
        ),

        const SizedBox(height: GymGoSpacing.md),

        // Pending payments alert
        if (overview.pendingPayments > 0)
          GymGoCard(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GymGoColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    color: GymGoColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: GymGoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pagos Pendientes',
                        style: GymGoTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tienes pagos por cobrar',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(overview.pendingPayments),
                  style: GymGoTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GymGoColors.warning,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: GymGoSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            amount,
            style: GymGoTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.icon,
    required this.percentage,
  });

  final String label;
  final String amount;
  final IconData icon;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: GymGoColors.textSecondary,
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: GymGoTypography.bodyMedium,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: GymGoTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: GymGoTypography.labelSmall.copyWith(
                color: GymGoColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
