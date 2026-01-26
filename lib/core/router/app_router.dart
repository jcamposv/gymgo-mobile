import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart' as app;
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../splash/splash_screen.dart';
import '../../features/dashboard/presentation/screens/home_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/workouts/presentation/screens/workouts_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/measurements/presentation/screens/measurements_screen.dart';
import '../../features/routines/presentation/screens/routines_screen.dart';
import '../../features/routines/presentation/screens/routine_detail_screen.dart';
import '../../features/routines/presentation/screens/program_overview_screen.dart';
import '../../features/routines/presentation/screens/workout_day_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/notification_settings_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/terms_screen.dart';
import '../../features/admin_tools/presentation/screens/admin_tools_screen.dart';
import '../../features/admin_tools/presentation/screens/create_class_screen.dart';
import '../../features/admin_tools/presentation/screens/templates_screen.dart';
import '../../features/admin_tools/presentation/screens/members_list_screen.dart';
import '../../features/admin_tools/presentation/screens/booking_limits_screen.dart';
import '../../features/admin_tools/presentation/screens/check_in_screen.dart';
import '../../features/finances/presentation/screens/finances_screen.dart';
import '../../features/finances/presentation/screens/create_payment_screen.dart';
import '../../features/finances/presentation/screens/create_expense_screen.dart';
import '../../features/finances/presentation/screens/create_income_screen.dart';
import '../../features/benchmarks/presentation/screens/benchmarks_screen.dart';
import '../../features/benchmarks/presentation/screens/prs_screen.dart';
import '../../features/benchmarks/presentation/screens/pr_detail_screen.dart';
import '../services/notification_service.dart';
import 'routes.dart';

/// Provider for GoRouter with authentication
final routerProvider = Provider<GoRouter>((ref) {
  // Use global navigator key from notification service for deep linking
  final rootNavigatorKey = navigatorKey;
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = authState is app.Authenticated;
      final isAuthRoute = _isAuthRoute(state.matchedLocation);
      final isSplash = _isSplashRoute(state.matchedLocation);
      final isResetPassword = state.matchedLocation == Routes.resetPassword;

      // Never redirect away from splash - let animation complete
      if (isSplash) {
        return null;
      }

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
      // Splash screen (initial route)
      GoRoute(
        path: Routes.splash,
        name: Routes.splashName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SplashScreen(),
        ),
      ),

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

      // Routine detail (full screen, no bottom nav)
      GoRoute(
        path: '/member/routines/:id',
        name: Routes.memberRoutineDetailName,
        pageBuilder: (context, state) {
          final routineId = state.pathParameters['id']!;
          return _buildPageWithTransition(
            context,
            state,
            RoutineDetailScreen(routineId: routineId),
          );
        },
      ),

      // Program overview (full screen, no bottom nav)
      GoRoute(
        path: '/member/program/:programId',
        name: Routes.memberProgramName,
        pageBuilder: (context, state) {
          final programId = state.pathParameters['programId']!;
          return _buildPageWithTransition(
            context,
            state,
            ProgramOverviewScreen(programId: programId),
          );
        },
      ),

      // Workout day detail (full screen, no bottom nav)
      GoRoute(
        path: '/member/workout/:workoutId',
        name: Routes.memberWorkoutName,
        pageBuilder: (context, state) {
          final workoutId = state.pathParameters['workoutId']!;
          return _buildPageWithTransition(
            context,
            state,
            WorkoutDayScreen(workoutId: workoutId),
          );
        },
      ),

      // Notifications (full screen, no bottom nav)
      GoRoute(
        path: Routes.notifications,
        name: Routes.notificationsName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const NotificationsScreen(),
        ),
      ),

      // Profile sub-routes (full screen, no bottom nav)
      GoRoute(
        path: Routes.profileNotifications,
        name: Routes.profileNotificationsName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profileHelpSupport,
        name: Routes.profileHelpSupportName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const HelpSupportScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profileHelpCenter,
        name: Routes.profileHelpCenterName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const HelpCenterScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profileTerms,
        name: Routes.profileTermsName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const TermsScreen(),
        ),
      ),

      // Admin Tools routes (full screen, no bottom nav)
      GoRoute(
        path: Routes.adminTools,
        name: Routes.adminToolsName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const AdminToolsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminRegisterPayment,
        name: Routes.adminRegisterPaymentName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CreatePaymentScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminCreateClass,
        name: Routes.adminCreateClassName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CreateClassScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminTemplates,
        name: Routes.adminTemplatesName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const TemplatesScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminFinances,
        name: Routes.adminFinancesName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const FinancesScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminCreatePayment,
        name: Routes.adminCreatePaymentName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CreatePaymentScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminCreateExpense,
        name: Routes.adminCreateExpenseName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CreateExpenseScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminCreateIncome,
        name: Routes.adminCreateIncomeName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CreateIncomeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminMembers,
        name: Routes.adminMembersName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const MembersListScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminCheckIn,
        name: Routes.adminCheckInName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CheckInScreen(),
        ),
      ),
      GoRoute(
        path: Routes.adminBookingLimits,
        name: Routes.adminBookingLimitsName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const BookingLimitsScreen(),
        ),
      ),

      // Benchmarks routes (full screen, no bottom nav)
      GoRoute(
        path: Routes.benchmarks,
        name: Routes.benchmarksName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const BenchmarksScreen(),
        ),
      ),
      GoRoute(
        path: Routes.benchmarksPrs,
        name: Routes.benchmarksPrsName,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const PRsScreen(),
        ),
      ),
      GoRoute(
        path: '/benchmarks/prs/:exerciseId',
        name: Routes.benchmarksPrDetailName,
        pageBuilder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId']!;
          return _buildPageWithTransition(
            context,
            state,
            PRDetailScreen(exerciseId: exerciseId),
          );
        },
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
            path: Routes.memberRoutines,
            name: Routes.memberRoutinesName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const RoutinesScreen(),
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
            path: Routes.memberMeasurements,
            name: Routes.memberMeasurementsName,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const MeasurementsScreen(),
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

/// Check if route is splash (no redirect during animation)
bool _isSplashRoute(String path) {
  return path == Routes.splash;
}

/// Build page with fade transition
/// Uses ValueKey with full URI to ensure unique page keys
CustomTransitionPage<void> _buildPageWithTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  // Use full URI including query params to ensure unique keys
  final key = ValueKey('${state.matchedLocation}_${state.uri}');

  return CustomTransitionPage<void>(
    key: key,
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
