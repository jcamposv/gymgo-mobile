import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/app_notification.dart';
import '../providers/inbox_providers.dart';
import '../widgets/notification_tile.dart';

/// Screen displaying the notifications inbox
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize inbox on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboxProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: GymGoColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
        ),
        title: Text(
          'Notificaciones',
          style: GymGoTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (inboxState.unreadCount > 0)
            TextButton(
              onPressed: () => _markAllAsRead(),
              child: Text(
                'Marcar leídas',
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.primary,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(LucideIcons.checkCheck, size: 18),
                    SizedBox(width: 12),
                    Text('Marcar todas como leídas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 18, color: GymGoColors.error),
                    SizedBox(width: 12),
                    Text('Eliminar todas', style: TextStyle(color: GymGoColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
        color: GymGoColors.primary,
        backgroundColor: GymGoColors.surface,
        child: _buildBody(inboxState),
      ),
    );
  }

  Widget _buildBody(InboxState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return _buildLoadingState();
    }

    if (state.hasError && state.notifications.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    return _buildNotificationsList(state.notifications);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: GymGoSpacing.md),
      itemCount: 5,
      itemBuilder: (context, index) => _buildSkeletonTile(),
    );
  }

  Widget _buildSkeletonTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
        vertical: GymGoSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GymGoShimmerBox(width: 40, height: 40),
          const SizedBox(width: GymGoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                GymGoShimmerBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                GymGoShimmerBox(width: 200, height: 14),
                SizedBox(height: 8),
                GymGoShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: GymGoColors.error,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Error al cargar',
              style: GymGoTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error,
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.read(inboxProvider.notifier).initialize(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(GymGoSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: GymGoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  LucideIcons.bellOff,
                  size: 48,
                  color: GymGoColors.textTertiary,
                ),
              ),
              const SizedBox(height: GymGoSpacing.lg),
              Text(
                'No tienes notificaciones',
                style: GymGoTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: GymGoSpacing.sm),
              Text(
                'Las notificaciones de nuevas clases,\nrutinas y más aparecerán aquí',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationTile(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onDismiss: () => _deleteNotification(notification.id),
        ).animate().fadeIn(
          duration: 200.ms,
          delay: (index * 50).ms,
        );
      },
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    ref.read(inboxProvider.notifier).markAsRead(notification.id);

    // Navigate based on notification type
    _navigateToTarget(notification);
  }

  void _navigateToTarget(AppNotification notification) {
    if (notification.isClassRelated) {
      // Navigate to classes screen
      // If we have a specific date, use it
      final scheduledDate = notification.scheduledDate;
      if (scheduledDate != null) {
        // Navigate to classes with the specific date
        context.go(Routes.memberClasses);
      } else {
        context.go(Routes.memberClasses);
      }
    } else if (notification.isRoutineRelated) {
      // Navigate to routines
      final routineId = notification.routineId;
      if (routineId != null) {
        context.go('/member/routines/$routineId');
      } else {
        context.go(Routes.memberRoutines);
      }
    } else {
      // For other types, just close the screen
      context.pop();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _markAllAsRead() {
    ref.read(inboxProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Todas las notificaciones marcadas como leídas'),
        backgroundColor: GymGoColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(String id) {
    ref.read(inboxProvider.notifier).delete(id);
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.surface,
        title: const Text('Eliminar todas'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las notificaciones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: GymGoColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(inboxProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Notificaciones eliminadas'),
                  backgroundColor: GymGoColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: GymGoColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
