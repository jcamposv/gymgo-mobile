/// Role-Based Access Control types for GymGo mobile
///
/// Mirrors the web RBAC system in web/src/lib/rbac/types.ts

/// Application roles
enum AppRole {
  superAdmin('super_admin'),
  admin('admin'),
  assistant('assistant'),
  trainer('trainer'),
  nutritionist('nutritionist'),
  client('client');

  const AppRole(this.value);
  final String value;

  /// Parse role from string (database value)
  static AppRole fromString(String? value) {
    if (value == null || value.isEmpty) return AppRole.client;

    // Handle legacy role names
    switch (value.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return AppRole.superAdmin;
      case 'admin':
      case 'owner':
        return AppRole.admin;
      case 'assistant':
        return AppRole.assistant;
      case 'trainer':
      case 'coach':
        return AppRole.trainer;
      case 'nutritionist':
        return AppRole.nutritionist;
      case 'client':
      case 'member':
      default:
        return AppRole.client;
    }
  }

  /// Human-readable label (Spanish)
  String get label {
    switch (this) {
      case AppRole.superAdmin:
        return 'Super Administrador';
      case AppRole.admin:
        return 'Administrador';
      case AppRole.assistant:
        return 'Asistente';
      case AppRole.trainer:
        return 'Entrenador';
      case AppRole.nutritionist:
        return 'Nutricionista';
      case AppRole.client:
        return 'Cliente';
    }
  }

  /// Role description (Spanish)
  String get description {
    switch (this) {
      case AppRole.superAdmin:
        return 'Acceso completo a la plataforma y todas las organizaciones';
      case AppRole.admin:
        return 'Acceso completo al gimnasio, incluyendo finanzas y configuración';
      case AppRole.assistant:
        return 'Gestión operativa del gimnasio sin acceso a finanzas';
      case AppRole.trainer:
        return 'Gestión de rutinas, métricas y notas de miembros';
      case AppRole.nutritionist:
        return 'Gestión de métricas nutricionales y reportes de miembros';
      case AppRole.client:
        return 'Acceso a sus propios datos, rutinas y progreso';
    }
  }
}

/// Application permissions
enum AppPermission {
  // Dashboard access
  viewAdminDashboard('view_admin_dashboard'),
  viewClientDashboard('view_client_dashboard'),
  viewTrainerDashboard('view_trainer_dashboard'),

  // Gym settings & configuration
  manageGymSettings('manage_gym_settings'),
  manageGymBranding('manage_gym_branding'),

  // Financial - Overview & Configuration (Admin only)
  viewGymFinances('view_gym_finances'),
  manageGymFinances('manage_gym_finances'),
  viewReports('view_reports'),

  // Financial - Operations (Admin & Assistant)
  createPayments('create_payments'),
  createExpenses('create_expenses'),
  viewMemberPaymentStatus('view_member_payment_status'),

  // Membership plans
  viewPlans('view_plans'),
  managePlans('manage_plans'),

  // Members management
  viewMembers('view_members'),
  manageMembers('manage_members'),
  inviteMembers('invite_members'),
  viewAnyMemberProfile('view_any_member_profile'),

  // Classes
  viewClasses('view_classes'),
  manageClasses('manage_classes'),
  manageClassTemplates('manage_class_templates'),

  // Exercises & Routines
  viewExercises('view_exercises'),
  manageExercises('manage_exercises'),
  viewAnyMemberRoutines('view_any_member_routines'),
  manageAnyMemberRoutines('manage_any_member_routines'),
  assignRoutines('assign_routines'),

  // Metrics & Measurements
  viewAnyMemberMetrics('view_any_member_metrics'),
  manageAnyMemberMetrics('manage_any_member_metrics'),

  // Notes
  viewAnyMemberNotes('view_any_member_notes'),
  manageAnyMemberNotes('manage_any_member_notes'),

  // Reports
  viewAnyMemberReports('view_any_member_reports'),
  manageAnyMemberReports('manage_any_member_reports'),

  // Check-in system
  viewCheckIns('view_check_ins'),
  manageCheckIns('manage_check_ins'),
  performCheckIn('perform_check_in'),

  // Bookings
  viewAnyBookings('view_any_bookings'),
  manageAnyBookings('manage_any_bookings'),

  // Own data
  viewOwnMemberProfile('view_own_member_profile'),
  editOwnMemberProfile('edit_own_member_profile'),
  viewOwnRoutines('view_own_routines'),
  viewOwnMetrics('view_own_metrics'),
  viewOwnReports('view_own_reports'),
  viewOwnBookings('view_own_bookings'),
  manageOwnBookings('manage_own_bookings'),

  // Staff management
  viewStaff('view_staff'),
  manageStaff('manage_staff'),

  // Platform admin
  viewAllOrganizations('view_all_organizations'),
  manageAllOrganizations('manage_all_organizations');

  const AppPermission(this.value);
  final String value;
}

/// Staff roles (anyone who can manage the gym)
const staffRoles = [
  AppRole.superAdmin,
  AppRole.admin,
  AppRole.assistant,
  AppRole.trainer,
  AppRole.nutritionist,
];

/// Admin-level roles (full dashboard access)
const adminRoles = [
  AppRole.superAdmin,
  AppRole.admin,
];

/// Roles that can access Admin Tools
const adminToolsRoles = [
  AppRole.superAdmin,
  AppRole.admin,
  AppRole.assistant,
];
