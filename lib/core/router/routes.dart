/// App route paths
class Routes {
  Routes._();

  // Splash route
  static const String splash = '/';

  // Auth routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main routes (with bottom nav)
  static const String home = '/home';
  static const String memberClasses = '/member/classes';
  static const String memberWorkouts = '/member/workouts';
  static const String memberRoutines = '/member/routines';
  static const String memberRoutineDetail = '/member/routines/:id';
  static const String memberProgress = '/member/progress';
  static const String memberMeasurements = '/member/measurements';
  static const String profile = '/profile';

  // Profile sub-routes
  static const String profileNotifications = '/profile/notifications';
  static const String profileHelpSupport = '/profile/help';
  static const String profileHelpCenter = '/profile/help/center';
  static const String profileTerms = '/profile/terms';

  // Notifications
  static const String notifications = '/notifications';

  // Admin Tools routes
  static const String adminTools = '/admin';
  static const String adminRegisterPayment = '/admin/register-payment';
  static const String adminCreateClass = '/admin/create-class';
  static const String adminTemplates = '/admin/templates';
  static const String adminFinances = '/admin/finances';
  static const String adminCreatePayment = '/admin/finances/create-payment';
  static const String adminCreateExpense = '/admin/finances/create-expense';
  static const String adminCreateIncome = '/admin/finances/create-income';
  static const String adminMembers = '/admin/members';
  static const String adminCheckIn = '/admin/check-in';
  static const String adminBookingLimits = '/admin/booking-limits';

  // Route names for navigation
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String forgotPasswordName = 'forgot-password';
  static const String resetPasswordName = 'reset-password';
  static const String homeName = 'home';
  static const String memberClassesName = 'member-classes';
  static const String memberWorkoutsName = 'member-workouts';
  static const String memberRoutinesName = 'member-routines';
  static const String memberRoutineDetailName = 'member-routine-detail';
  static const String memberProgressName = 'member-progress';
  static const String memberMeasurementsName = 'member-measurements';
  static const String profileName = 'profile';
  static const String profileNotificationsName = 'profile-notifications';
  static const String profileHelpSupportName = 'profile-help';
  static const String profileHelpCenterName = 'profile-help-center';
  static const String profileTermsName = 'profile-terms';
  static const String notificationsName = 'notifications';

  // Admin route names
  static const String adminToolsName = 'admin-tools';
  static const String adminRegisterPaymentName = 'admin-register-payment';
  static const String adminCreateClassName = 'admin-create-class';
  static const String adminTemplatesName = 'admin-templates';
  static const String adminFinancesName = 'admin-finances';
  static const String adminCreatePaymentName = 'admin-create-payment';
  static const String adminCreateExpenseName = 'admin-create-expense';
  static const String adminCreateIncomeName = 'admin-create-income';
  static const String adminMembersName = 'admin-members';
  static const String adminCheckInName = 'admin-check-in';
  static const String adminBookingLimitsName = 'admin-booking-limits';

  // Benchmarks routes
  static const String benchmarks = '/benchmarks';
  static const String benchmarksPrs = '/benchmarks/prs';
  static const String benchmarksPrDetail = '/benchmarks/prs/:exerciseId';

  // Benchmarks route names
  static const String benchmarksName = 'benchmarks';
  static const String benchmarksPrsName = 'benchmarks-prs';
  static const String benchmarksPrDetailName = 'benchmarks-pr-detail';

  // Program routes (new training programs system)
  static const String memberProgram = '/member/program/:programId';
  static const String memberWorkout = '/member/workout/:workoutId';

  // Program route names
  static const String memberProgramName = 'member-program';
  static const String memberWorkoutName = 'member-workout';

  // Membership routes
  static const String membership = '/membership';
  static const String membershipPayments = '/membership/payments';

  // Membership route names
  static const String membershipName = 'membership';
  static const String membershipPaymentsName = 'membership-payments';
}
