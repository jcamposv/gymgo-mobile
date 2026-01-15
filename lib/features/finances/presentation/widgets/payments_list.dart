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

/// Payments list widget
class PaymentsList extends ConsumerWidget {
  const PaymentsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider);

    return paymentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GymGoColors.primary),
      ),
      error: (error, stack) => _buildError(context, ref, error),
      data: (result) {
        if (result.data.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(paymentsProvider),
          color: GymGoColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.screenHorizontal,
            ),
            itemCount: result.data.length,
            itemBuilder: (context, index) {
              final payment = result.data[index];
              return PaymentTile(payment: payment);
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
              'Error al cargar pagos',
              style: GymGoTypography.bodyLarge.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(paymentsProvider),
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
                LucideIcons.receipt,
                size: 32,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Sin pagos',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No hay pagos registrados para este período.',
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

/// Individual payment tile
class PaymentTile extends StatelessWidget {
  const PaymentTile({super.key, required this.payment});

  final Payment payment;

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
          // Status indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getStatusColor(payment.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: Icon(
              _getStatusIcon(payment.status),
              size: 22,
              color: _getStatusColor(payment.status),
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.memberName ?? 'Miembro',
                  style: GymGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _getMethodIcon(payment.paymentMethod),
                      size: 12,
                      color: GymGoColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.paymentMethod.label,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    ),
                    if (payment.planName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GymGoColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          payment.planName!,
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(payment.createdAt),
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
                currencyFormat.format(payment.amount),
                style: GymGoTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: GymGoColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(payment.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.status.label,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: _getStatusColor(payment.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return GymGoColors.success;
      case PaymentStatus.pending:
        return GymGoColors.warning;
      case PaymentStatus.failed:
        return GymGoColors.error;
      case PaymentStatus.refunded:
        return GymGoColors.info;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return LucideIcons.checkCircle;
      case PaymentStatus.pending:
        return LucideIcons.clock;
      case PaymentStatus.failed:
        return LucideIcons.xCircle;
      case PaymentStatus.refunded:
        return LucideIcons.rotateCcw;
    }
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return LucideIcons.banknote;
      case PaymentMethod.card:
        return LucideIcons.creditCard;
      case PaymentMethod.transfer:
        return LucideIcons.arrowLeftRight;
      case PaymentMethod.other:
        return LucideIcons.wallet;
    }
  }
}
