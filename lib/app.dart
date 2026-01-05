import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/gymgo_theme.dart';

/// GymGo Mobile App
class GymGoApp extends ConsumerWidget {
  const GymGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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
