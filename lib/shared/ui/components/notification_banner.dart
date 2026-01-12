import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/config/notification_channels.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/gymgo_colors.dart';
import '../../../core/theme/gymgo_spacing.dart';
import '../../../core/theme/gymgo_typography.dart';
import '../../../features/classes/presentation/providers/classes_providers.dart';

/// In-app notification banner for foreground notifications
///
/// Shows a Material banner at the top of the screen when a push notification
/// arrives while the app is in foreground. Includes action to view the
/// related content.
class NotificationBanner {
  NotificationBanner._();

  static OverlayEntry? _currentBanner;

  /// Show notification banner
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    Map<String, String>? data,
    WidgetRef? ref,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Remove existing banner if any
    dismiss();

    final overlay = Overlay.of(context);
    final type = data?['type'] ?? '';

    _currentBanner = OverlayEntry(
      builder: (context) => _NotificationBannerWidget(
        title: title,
        body: body,
        type: type,
        data: data,
        ref: ref,
        onDismiss: dismiss,
        onTap: () {
          dismiss();
          _handleTap(context, data, ref);
        },
      ),
    );

    overlay.insert(_currentBanner!);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      dismiss();
    });
  }

  /// Dismiss the current banner
  static void dismiss() {
    _currentBanner?.remove();
    _currentBanner = null;
  }

  /// Handle banner tap - navigate to relevant screen
  static void _handleTap(
    BuildContext context,
    Map<String, String>? data,
    WidgetRef? ref,
  ) {
    if (data == null) return;

    final type = data['type'];
    final startTimeStr = data['startTime'];

    switch (type) {
      case NotificationTypes.classCreated:
      case NotificationTypes.classUpdated:
      case NotificationTypes.classCancelled:
      case NotificationTypes.classReminder:
      case NotificationTypes.bookingConfirmed:
      case NotificationTypes.bookingCancelled:
        // Parse date and select it
        if (startTimeStr != null && ref != null) {
          try {
            final startTime = DateTime.parse(startTimeStr);
            ref.read(selectedDateProvider.notifier).state = startTime;
          } catch (_) {}
        }
        // Refresh classes
        ref?.invalidate(classesProvider);
        // Navigate
        context.go(Routes.memberClasses);
        break;

      default:
        context.go(Routes.home);
    }
  }
}

/// Animated notification banner widget
class _NotificationBannerWidget extends StatefulWidget {
  const _NotificationBannerWidget({
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
    required this.onTap,
    this.data,
    this.ref,
  });

  final String title;
  final String body;
  final String type;
  final Map<String, String>? data;
  final WidgetRef? ref;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case NotificationTypes.classCreated:
        return LucideIcons.calendarPlus;
      case NotificationTypes.classUpdated:
        return LucideIcons.calendarClock;
      case NotificationTypes.classCancelled:
        return LucideIcons.calendarX;
      case NotificationTypes.classReminder:
        return LucideIcons.bellRing;
      case NotificationTypes.bookingConfirmed:
        return LucideIcons.checkCircle;
      case NotificationTypes.bookingCancelled:
        return LucideIcons.xCircle;
      case NotificationTypes.announcement:
        return LucideIcons.megaphone;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case NotificationTypes.classCreated:
        return GymGoColors.primary;
      case NotificationTypes.classUpdated:
        return GymGoColors.info;
      case NotificationTypes.classCancelled:
        return GymGoColors.error;
      case NotificationTypes.bookingConfirmed:
        return GymGoColors.success;
      case NotificationTypes.bookingCancelled:
        return GymGoColors.warning;
      default:
        return GymGoColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final iconColor = _getColorForType(widget.type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                // Swiped up - dismiss
                widget.onDismiss();
              }
            },
            child: Container(
              margin: EdgeInsets.only(top: topPadding),
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
                vertical: GymGoSpacing.md,
              ),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                      ),
                      child: Icon(
                        _getIconForType(widget.type),
                        color: iconColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: GymGoSpacing.md),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: GymGoTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: GymGoTypography.bodySmall.copyWith(
                              color: GymGoColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: GymGoSpacing.sm),

                    // View button
                    TextButton(
                      onPressed: widget.onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: GymGoColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: GymGoSpacing.sm,
                          vertical: GymGoSpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Ver'),
                    ),

                    // Close button
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: GymGoColors.textTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
