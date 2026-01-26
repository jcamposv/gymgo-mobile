import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/membership_models.dart';
import '../providers/membership_providers.dart';

/// Screen showing payment history
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  static const _monthsShort = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentHistoryProvider);
        },
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildPaymentsList(context, payments);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _buildErrorState(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    List<PaymentRecord> payments,
  ) {
    // Group payments by month
    final groupedPayments = <String, List<PaymentRecord>>{};

    for (final payment in payments) {
      final monthKey = '${_months[payment.createdAt.month - 1]} ${payment.createdAt.year}';
      groupedPayments.putIfAbsent(monthKey, () => []).add(payment);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groupedPayments.length,
      itemBuilder: (context, index) {
        final monthKey = groupedPayments.keys.elementAt(index);
        final monthPayments = groupedPayments[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthHeader(context, monthKey),
            ...monthPayments.map(
              (payment) => _buildPaymentCard(context, payment),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthHeader(BuildContext context, String month) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        month,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentRecord payment) {
    final theme = Theme.of(context);
    final statusStyle = _getStatusStyle(context, payment.status);
    final dateStr = '${payment.createdAt.day} ${_monthsShort[payment.createdAt.month - 1]} ${payment.createdAt.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Plan name and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.planName ?? 'Pago',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(payment.amount, payment.currency),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusStyle.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusStyle.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Payment method and notes
            if (payment.paymentMethod != null || payment.notes != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (payment.paymentMethod != null)
                _buildDetailRow(
                  context,
                  Icons.payment_outlined,
                  _getPaymentMethodLabel(payment.paymentMethod!),
                ),
              if (payment.notes != null) ...[
                if (payment.paymentMethod != null) const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  Icons.notes_outlined,
                  payment.notes!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin pagos registrados',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán tus pagos cuando realices uno.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar pagos',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(paymentHistoryProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    final symbol = currency == 'MXN' ? r'$' : currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  String _getPaymentMethodLabel(String method) {
    const labels = {
      'cash': 'Efectivo',
      'card': 'Tarjeta',
      'transfer': 'Transferencia',
      'other': 'Otro',
    };
    return labels[method] ?? method;
  }

  _PaymentStatusStyle _getStatusStyle(BuildContext context, String status) {
    switch (status) {
      case 'paid':
        return _PaymentStatusStyle(
          backgroundColor: Colors.green.shade50,
          textColor: Colors.green.shade700,
          label: 'Pagado',
        );
      case 'pending':
        return _PaymentStatusStyle(
          backgroundColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
          label: 'Pendiente',
        );
      case 'cancelled':
        return _PaymentStatusStyle(
          backgroundColor: Colors.red.shade50,
          textColor: Colors.red.shade700,
          label: 'Cancelado',
        );
      case 'refunded':
        return _PaymentStatusStyle(
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade700,
          label: 'Reembolsado',
        );
      default:
        return _PaymentStatusStyle(
          backgroundColor: Colors.grey.shade100,
          textColor: Colors.grey.shade700,
          label: status,
        );
    }
  }
}

class _PaymentStatusStyle {
  const _PaymentStatusStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
  });

  final Color backgroundColor;
  final Color textColor;
  final String label;
}
