/// App route paths
class Routes {
  Routes._();

  // Auth routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main routes (with bottom nav)
  static const String home = '/home';
  static const String memberClasses = '/member/classes';
  static const String memberWorkouts = '/member/workouts';
  static const String memberProgress = '/member/progress';
  static const String profile = '/profile';

  // Route names for navigation
  static const String loginName = 'login';
  static const String forgotPasswordName = 'forgot-password';
  static const String resetPasswordName = 'reset-password';
  static const String homeName = 'home';
  static const String memberClassesName = 'member-classes';
  static const String memberWorkoutsName = 'member-workouts';
  static const String memberProgressName = 'member-progress';
  static const String profileName = 'profile';
}
