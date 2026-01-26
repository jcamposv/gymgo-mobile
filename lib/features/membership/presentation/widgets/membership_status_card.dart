import 'package:flutter/material.dart';

import '../../domain/membership_models.dart';
import '../providers/membership_providers.dart';

/// Card showing membership status with visual indicator
class MembershipStatusCard extends StatelessWidget {
  const MembershipStatusCard({
    super.key,
    required this.membership,
  });

  final MembershipInfo membership;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _getStatusStyle(context, membership.status);

    return Card(
      color: statusStyle.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusStyle.iconBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusStyle.icon,
                    color: statusStyle.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de Membresía',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusStyle.textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        membership.status.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: statusStyle.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: statusStyle.textColor.withOpacity(0.2)),
            const SizedBox(height: 16),

            // Status description
            Text(
              membership.status.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusStyle.textColor.withOpacity(0.9),
              ),
            ),

            // Days remaining (if applicable)
            if (membership.daysRemaining != null &&
                membership.status != MembershipStatus.expired &&
                membership.status != MembershipStatus.noMembership) ...[
              const SizedBox(height: 16),
              _buildDaysRemainingBadge(context, statusStyle),
            ],

            // Expiration warning
            if (membership.status == MembershipStatus.expiringSoon) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusStyle.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: statusStyle.iconColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Renueva antes del ${_formatDate(membership.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusStyle.iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaysRemainingBadge(
    BuildContext context,
    _StatusStyle statusStyle,
  ) {
    final theme = Theme.of(context);
    final days = membership.daysRemaining!;
    final daysText = days == 1 ? 'día' : 'días';

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 18,
          color: statusStyle.textColor.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          '$days $daysText restantes',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: statusStyle.textColor.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  _StatusStyle _getStatusStyle(BuildContext context, MembershipStatus status) {
    final theme = Theme.of(context);

    switch (status) {
      case MembershipStatus.active:
        return _StatusStyle(
          backgroundColor: Colors.green.shade50,
          iconBackgroundColor: Colors.green.shade100,
          iconColor: Colors.green.shade700,
          textColor: Colors.green.shade900,
          icon: Icons.check_circle,
        );
      case MembershipStatus.expiringSoon:
        return _StatusStyle(
          backgroundColor: Colors.orange.shade50,
          iconBackgroundColor: Colors.orange.shade100,
          iconColor: Colors.orange.shade700,
          textColor: Colors.orange.shade900,
          icon: Icons.schedule,
        );
      case MembershipStatus.expired:
        return _StatusStyle(
          backgroundColor: Colors.red.shade50,
          iconBackgroundColor: Colors.red.shade100,
          iconColor: Colors.red.shade700,
          textColor: Colors.red.shade900,
          icon: Icons.cancel,
        );
      case MembershipStatus.noMembership:
        return _StatusStyle(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          iconBackgroundColor: theme.colorScheme.surfaceContainerHigh,
          iconColor: theme.colorScheme.outline,
          textColor: theme.colorScheme.onSurface,
          icon: Icons.card_membership_outlined,
        );
    }
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
}
