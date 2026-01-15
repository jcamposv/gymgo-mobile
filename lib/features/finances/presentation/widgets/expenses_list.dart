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

/// Expenses list widget
class ExpensesList extends ConsumerWidget {
  const ExpensesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return expensesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GymGoColors.primary),
      ),
      error: (error, stack) => _buildError(context, ref, error),
      data: (result) {
        if (result.data.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(expensesProvider),
          color: GymGoColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.screenHorizontal,
            ),
            itemCount: result.data.length,
            itemBuilder: (context, index) {
              final expense = result.data[index];
              return ExpenseTile(expense: expense);
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
              'Error al cargar gastos',
              style: GymGoTypography.bodyLarge.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(expensesProvider),
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
              child: Icon(
                LucideIcons.receipt,
                size: 32,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Sin gastos',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No hay gastos registrados para este período.',
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

/// Individual expense tile
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

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
              color: GymGoColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              size: 22,
              color: GymGoColors.error,
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: GymGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: GymGoColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.category.label,
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.error,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (expense.vendor != null && expense.vendor!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.store,
                        size: 12,
                        color: GymGoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          expense.vendor!,
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(expense.expenseDate ?? expense.createdAt),
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${currencyFormat.format(expense.amount)}',
                style: GymGoTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GymGoColors.error,
                ),
              ),
              if (expense.isRecurring) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.repeat,
                        size: 10,
                        color: GymGoColors.info,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Recurrente',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.info,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return LucideIcons.home;
      case ExpenseCategory.utilities:
        return LucideIcons.zap;
      case ExpenseCategory.salaries:
        return LucideIcons.users;
      case ExpenseCategory.equipment:
        return LucideIcons.dumbbell;
      case ExpenseCategory.maintenance:
        return LucideIcons.wrench;
      case ExpenseCategory.marketing:
        return LucideIcons.megaphone;
      case ExpenseCategory.supplies:
        return LucideIcons.package;
      case ExpenseCategory.insurance:
        return LucideIcons.shield;
      case ExpenseCategory.taxes:
        return LucideIcons.landmark;
      case ExpenseCategory.other:
        return LucideIcons.moreHorizontal;
    }
  }
}
