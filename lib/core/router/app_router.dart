import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart' as app;
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/workouts/presentation/screens/workouts_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import 'routes.dart';

/// Provider for GoRouter with authentication
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.login,
    debugLogDiagnostics: true,
    refreshListenable: RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = authState is app.Authenticated;
      final isAuthRoute = _isAuthRoute(state.matchedLocation);
      final isResetPassword = state.matchedLocation == Routes.resetPassword;

      // Allow reset password route without authentication
      if (isResetPassword) {
        return null;
      }

      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return Routes.login;
      }

      // If authenticated and on auth route, redirect to home
      if (isAuthenticated && isAuthRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(
        path: Routes.login,
        name: Routes.loginName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: Routes.forgotPasswordName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: Routes.resetPassword,
        name: Routes.resetPasswordName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ResetPasswordScreen(),
        ),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            name: Routes.homeName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const HomeDashboardScreen(),
            ),
          ),
          GoRoute(
            path: Routes.memberClasses,
            name: Routes.memberClassesName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ClassesScreen(),
            ),
          ),
          GoRoute(
            path: Routes.memberWorkouts,
            name: Routes.memberWorkoutsName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const WorkoutsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.memberProgress,
            name: Routes.memberProgressName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ProgressScreen(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: Routes.profileName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => _buildPageWithTransition(
      context,
      state,
      _ErrorScreen(error: state.error),
    ),
  );
});

/// Check if route is an auth route
bool _isAuthRoute(String path) {
  return path == Routes.login ||
      path == Routes.forgotPassword ||
      path == Routes.resetPassword;
}

/// Build page with fade transition
CustomTransitionPage<void> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

/// Error screen
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'La página que buscas no existe',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Router refresh notifier for auth state changes
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}
