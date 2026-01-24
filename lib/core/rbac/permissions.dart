/// Role -> Permissions mapping for GymGo mobile
///
/// Mirrors the web RBAC system in web/src/lib/rbac/permissions.ts

import 'types.dart';

/// Centralized mapping of roles to their permissions
///
/// Note: super_admin was removed from mobile. Users with super_admin role
/// in the database are mapped to admin in mobile (full gym access).
final Map<AppRole, Set<AppPermission>> rolePermissions = {
  // ADMIN - Full gym access (includes super_admin mapped from DB)
  AppRole.admin: {
    // Dashboard
    AppPermission.viewAdminDashboard,
    AppPermission.viewClientDashboard,
    AppPermission.viewTrainerDashboard,
    // Gym management
    AppPermission.manageGymSettings,
    AppPermission.manageGymBranding,
    // Finances - Full access
    AppPermission.viewGymFinances,
    AppPermission.manageGymFinances,
    AppPermission.viewReports,
    AppPermission.createPayments,
    AppPermission.createExpenses,
    AppPermission.viewMemberPaymentStatus,
    // Plans
    AppPermission.viewPlans,
    AppPermission.managePlans,
    // Members
    AppPermission.viewMembers,
    AppPermission.manageMembers,
    AppPermission.inviteMembers,
    AppPermission.viewAnyMemberProfile,
    // Classes
    AppPermission.viewClasses,
    AppPermission.manageClasses,
    AppPermission.manageClassTemplates,
    // Exercises & Routines
    AppPermission.viewExercises,
    AppPermission.manageExercises,
    AppPermission.viewAnyMemberRoutines,
    AppPermission.manageAnyMemberRoutines,
    AppPermission.assignRoutines,
    // Metrics
    AppPermission.viewAnyMemberMetrics,
    AppPermission.manageAnyMemberMetrics,
    // Notes
    AppPermission.viewAnyMemberNotes,
    AppPermission.manageAnyMemberNotes,
    // Reports
    AppPermission.viewAnyMemberReports,
    AppPermission.manageAnyMemberReports,
    // Check-in
    AppPermission.viewCheckIns,
    AppPermission.manageCheckIns,
    AppPermission.performCheckIn,
    // Bookings
    AppPermission.viewAnyBookings,
    AppPermission.manageAnyBookings,
    // Own data
    AppPermission.viewOwnMemberProfile,
    AppPermission.editOwnMemberProfile,
    AppPermission.viewOwnRoutines,
    AppPermission.viewOwnMetrics,
    AppPermission.viewOwnReports,
    AppPermission.viewOwnBookings,
    AppPermission.manageOwnBookings,
    // Staff
    AppPermission.viewStaff,
    AppPermission.manageStaff,
  },

  // ASSISTANT - Most permissions except finances/settings
  AppRole.assistant: {
    // Dashboard
    AppPermission.viewAdminDashboard,
    AppPermission.viewClientDashboard,
    AppPermission.viewTrainerDashboard,
    // NO gym settings/branding
    // NO full finance access (viewGymFinances, manageGymFinances)
    // Finance Operations - Can register but NOT view aggregated data
    AppPermission.createPayments,
    AppPermission.createExpenses,
    AppPermission.viewMemberPaymentStatus,
    // Reports (read-only)
    AppPermission.viewReports,
    // Plans (read-only)
    AppPermission.viewPlans,
    // Members
    AppPermission.viewMembers,
    AppPermission.manageMembers,
    AppPermission.inviteMembers,
    AppPermission.viewAnyMemberProfile,
    // Classes
    AppPermission.viewClasses,
    AppPermission.manageClasses,
    AppPermission.manageClassTemplates,
    // Exercises & Routines
    AppPermission.viewExercises,
    AppPermission.manageExercises,
    AppPermission.viewAnyMemberRoutines,
    AppPermission.manageAnyMemberRoutines,
    AppPermission.assignRoutines,
    // Metrics
    AppPermission.viewAnyMemberMetrics,
    AppPermission.manageAnyMemberMetrics,
    // Notes
    AppPermission.viewAnyMemberNotes,
    AppPermission.manageAnyMemberNotes,
    // Reports
    AppPermission.viewAnyMemberReports,
    AppPermission.manageAnyMemberReports,
    // Check-in
    AppPermission.viewCheckIns,
    AppPermission.manageCheckIns,
    AppPermission.performCheckIn,
    // Bookings
    AppPermission.viewAnyBookings,
    AppPermission.manageAnyBookings,
    // Own data
    AppPermission.viewOwnMemberProfile,
    AppPermission.editOwnMemberProfile,
    AppPermission.viewOwnRoutines,
    AppPermission.viewOwnMetrics,
    AppPermission.viewOwnReports,
    AppPermission.viewOwnBookings,
    AppPermission.manageOwnBookings,
    // Staff (view only)
    AppPermission.viewStaff,
  },

  // TRAINER
  AppRole.trainer: {
    // Dashboard
    AppPermission.viewAdminDashboard,
    AppPermission.viewTrainerDashboard,
    AppPermission.viewClientDashboard,
    // Finance - Limited
    AppPermission.viewMemberPaymentStatus,
    // Members (view only)
    AppPermission.viewMembers,
    AppPermission.viewAnyMemberProfile,
    // Classes
    AppPermission.viewClasses,
    AppPermission.manageClasses,
    // Exercises & Routines (full access)
    AppPermission.viewExercises,
    AppPermission.manageExercises,
    AppPermission.viewAnyMemberRoutines,
    AppPermission.manageAnyMemberRoutines,
    AppPermission.assignRoutines,
    // Metrics
    AppPermission.viewAnyMemberMetrics,
    AppPermission.manageAnyMemberMetrics,
    // Notes
    AppPermission.viewAnyMemberNotes,
    AppPermission.manageAnyMemberNotes,
    // Reports (view only)
    AppPermission.viewAnyMemberReports,
    // Check-in
    AppPermission.performCheckIn,
    // Own data
    AppPermission.viewOwnMemberProfile,
    AppPermission.editOwnMemberProfile,
    AppPermission.viewOwnRoutines,
    AppPermission.viewOwnMetrics,
    AppPermission.viewOwnReports,
    AppPermission.viewOwnBookings,
    AppPermission.manageOwnBookings,
  },

  // NUTRITIONIST
  AppRole.nutritionist: {
    // Dashboard
    AppPermission.viewAdminDashboard,
    AppPermission.viewTrainerDashboard,
    AppPermission.viewClientDashboard,
    // Members (view only)
    AppPermission.viewMembers,
    AppPermission.viewAnyMemberProfile,
    // Classes (view only)
    AppPermission.viewClasses,
    // Exercises (view only)
    AppPermission.viewExercises,
    // Routines (view only)
    AppPermission.viewAnyMemberRoutines,
    // Metrics (full access)
    AppPermission.viewAnyMemberMetrics,
    AppPermission.manageAnyMemberMetrics,
    // Notes (full access)
    AppPermission.viewAnyMemberNotes,
    AppPermission.manageAnyMemberNotes,
    // Reports
    AppPermission.viewAnyMemberReports,
    AppPermission.manageAnyMemberReports,
    // Own data
    AppPermission.viewOwnMemberProfile,
    AppPermission.editOwnMemberProfile,
    AppPermission.viewOwnRoutines,
    AppPermission.viewOwnMetrics,
    AppPermission.viewOwnReports,
    AppPermission.viewOwnBookings,
    AppPermission.manageOwnBookings,
  },

  // CLIENT - Own data only
  AppRole.client: {
    // Dashboard
    AppPermission.viewClientDashboard,
    // Classes (view for booking)
    AppPermission.viewClasses,
    // Check-in
    AppPermission.performCheckIn,
    // Own data only
    AppPermission.viewOwnMemberProfile,
    AppPermission.editOwnMemberProfile,
    AppPermission.viewOwnRoutines,
    AppPermission.viewOwnMetrics,
    AppPermission.viewOwnReports,
    AppPermission.viewOwnBookings,
    AppPermission.manageOwnBookings,
  },
};

/// Check if a role has a specific permission
bool hasPermission(AppRole? role, AppPermission permission) {
  if (role == null) return false;
  return rolePermissions[role]?.contains(permission) ?? false;
}

/// Check if a role has any of the given permissions
bool hasAnyPermission(AppRole? role, List<AppPermission> permissions) {
  if (role == null) return false;
  final rolePerms = rolePermissions[role] ?? {};
  return permissions.any((p) => rolePerms.contains(p));
}

/// Check if a role has all of the given permissions
bool hasAllPermissions(AppRole? role, List<AppPermission> permissions) {
  if (role == null) return false;
  final rolePerms = rolePermissions[role] ?? {};
  return permissions.every((p) => rolePerms.contains(p));
}

/// Check if role is admin-level
bool isAdmin(AppRole? role) {
  return role == AppRole.admin;
}

/// Check if role is staff (can manage gym in some capacity)
bool isStaff(AppRole? role) {
  if (role == null) return false;
  return staffRoles.contains(role);
}

/// Check if role can access Admin Tools
bool canAccessAdminTools(AppRole? role) {
  if (role == null) return false;
  return adminToolsRoles.contains(role);
}
