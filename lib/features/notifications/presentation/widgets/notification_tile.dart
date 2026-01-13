import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/app_notification.dart';

/// A tile widget for displaying a single notification
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: GymGoSpacing.lg),
        color: GymGoColors.error,
        child: const Icon(
          LucideIcons.trash2,
          color: Colors.white,
          size: 20,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.screenHorizontal,
            vertical: GymGoSpacing.md,
          ),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : GymGoColors.primary.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: GymGoColors.cardBorder.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              _buildIcon(),
              const SizedBox(width: GymGoSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      notification.title,
                      style: GymGoTypography.bodyMedium.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: GymGoColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      // Body
                      Text(
                        notification.body,
                        style: GymGoTypography.bodySmall.copyWith(
                          color: GymGoColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      notification.timeAgo,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: GymGoColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: color,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case NotificationType.classCreated:
        return LucideIcons.calendarPlus;
      case NotificationType.classUpdated:
        return LucideIcons.calendarClock;
      case NotificationType.classCancelled:
        return LucideIcons.calendarX;
      case NotificationType.bookingConfirmed:
        return LucideIcons.calendarCheck;
      case NotificationType.bookingCancelled:
        return LucideIcons.calendarMinus;
      case NotificationType.routineUpdated:
      case NotificationType.routineAssigned:
        return LucideIcons.dumbbell;
      case NotificationType.measurementReminder:
        return LucideIcons.ruler;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case NotificationType.classCreated:
      case NotificationType.bookingConfirmed:
        return GymGoColors.success;
      case NotificationType.classCancelled:
      case NotificationType.bookingCancelled:
        return GymGoColors.error;
      case NotificationType.classUpdated:
        return GymGoColors.warning;
      case NotificationType.routineUpdated:
      case NotificationType.routineAssigned:
        return GymGoColors.info;
      case NotificationType.measurementReminder:
        return GymGoColors.primary;
      default:
        return GymGoColors.textSecondary;
    }
  }
}
