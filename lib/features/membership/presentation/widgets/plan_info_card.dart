import 'package:flutter/material.dart';

import '../../domain/membership_models.dart';

/// Card showing plan details
class PlanInfoCard extends StatelessWidget {
  const PlanInfoCard({
    super.key,
    required this.membership,
  });

  final MembershipInfo membership;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tu Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Plan name
            Text(
              membership.planName ?? 'Plan desconocido',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Details grid
            _buildDetailRow(
              context,
              Icons.calendar_today_outlined,
              'Fecha de inicio',
              _formatDate(membership.startDate),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.event_outlined,
              'Fecha de vencimiento',
              _formatDate(membership.endDate),
            ),

            if (membership.daysRemaining != null &&
                membership.daysRemaining! > 0) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.hourglass_bottom_outlined,
                'Días restantes',
                '${membership.daysRemaining} días',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
