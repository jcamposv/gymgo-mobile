import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/gymgo_theme.dart';
import 'shared/providers/notification_providers.dart';

/// GymGo Mobile App
class GymGoApp extends ConsumerStatefulWidget {
  const GymGoApp({super.key});

  @override
  ConsumerState<GymGoApp> createState() => _GymGoAppState();
}

class _GymGoAppState extends ConsumerState<GymGoApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    // Set the ref for the notification service
    NotificationService.instance.setRef(ref);

    // Initialize notification provider (syncs token to backend)
    await ref.read(notificationProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Listen for foreground notifications to show in-app alerts
    ref.listen(foregroundNotificationProvider, (previous, current) {
      if (current != null) {
        // Use ScaffoldMessenger for SnackBar instead of Overlay
        final scaffoldContext = navigatorKey.currentContext;
        if (scaffoldContext != null) {
          final title = current.notification?.title ?? (current.data['title'] as String?) ?? 'GymGo';
          final body = current.notification?.body ?? (current.data['body'] as String?) ?? '';

          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (body.isNotEmpty) Text(body),
                ],
              ),
              backgroundColor: const Color(0xFF1E1E1E),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Ver',
                textColor: const Color(0xFFCDFF00),
                onPressed: () {
                  // Navigate to classes
                  navigatorKey.currentContext?.go('/member/classes');
                },
              ),
            ),
          );
        }

        // Clear the notification after showing
        ref.read(notificationProvider.notifier).clearForegroundNotification();
      }
    });

    return MaterialApp.router(
      title: 'GymGo',
      debugShowCheckedModeBanner: false,
      theme: GymGoTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        // Apply text scale factor limits for accessibility
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
