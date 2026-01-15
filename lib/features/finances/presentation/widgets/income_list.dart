import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/finance_models.dart';
import '../providers/finances_providers.dart';

/// Income list widget
class IncomeList extends ConsumerWidget {
  const IncomeList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeListProvider);

    return incomeAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GymGoColors.primary),
      ),
      error: (error, stack) => _buildError(context, ref, error),
      data: (result) {
        if (result.data.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(incomeListProvider),
          color: GymGoColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.screenHorizontal,
            ),
            itemCount: result.data.length,
            itemBuilder: (context, index) {
              final income = result.data[index];
              return IncomeTile(income: income);
            },
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
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
              'Error al cargar ingresos',
              style: GymGoTypography.bodyLarge.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(incomeListProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.trendingUp,
                size: 32,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Sin ingresos',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No hay ingresos adicionales registrados para este período.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual income tile
class IncomeTile extends StatelessWidget {
  const IncomeTile({super.key, required this.income});

  final Income income;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return GymGoCard(
      margin: const EdgeInsets.only(bottom: GymGoSpacing.sm),
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Row(
        children: [
          // Category indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GymGoColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Icon(
              _getCategoryIcon(income.category),
              size: 22,
              color: GymGoColors.success,
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.description,
                  style: GymGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    income.category.label,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.success,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(income.incomeDate ?? income.createdAt),
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '+${currencyFormat.format(income.amount)}',
            style: GymGoTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: GymGoColors.success,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(IncomeCategory category) {
    switch (category) {
      case IncomeCategory.productSale:
        return LucideIcons.shoppingBag;
      case IncomeCategory.service:
        return LucideIcons.briefcase;
      case IncomeCategory.rental:
        return LucideIcons.key;
      case IncomeCategory.event:
        return LucideIcons.calendar;
      case IncomeCategory.donation:
        return LucideIcons.heart;
      case IncomeCategory.other:
        return LucideIcons.moreHorizontal;
    }
  }
}
