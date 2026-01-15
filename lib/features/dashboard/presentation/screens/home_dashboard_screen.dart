import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../shared/providers/branding_providers.dart';
import '../../../../shared/providers/role_providers.dart';
import '../../../classes/presentation/providers/classes_providers.dart';
import '../../../measurements/presentation/providers/measurements_providers.dart';
import '../../../profile/presentation/providers/member_providers.dart';
import '../widgets/admin_tools_card.dart';
import '../widgets/home_header.dart';
import '../widgets/next_class_card.dart';
import '../widgets/today_workout_card.dart';
import '../widgets/last_measurement_card.dart';
import '../widgets/quick_actions_grid.dart';

/// Home Dashboard Screen with smart cards
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the next user class from Supabase
    final nextClassAsync = ref.watch(nextUserClassProvider);
    // Watch user profile for role-based UI
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh all data providers
            ref.invalidate(nextUserClassProvider);
            ref.invalidate(gymBrandingProvider);
          },
          color: GymGoColors.primary,
          backgroundColor: GymGoColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: GymGoSpacing.md,
                    bottom: GymGoSpacing.lg,
                  ),
                  child: HomeHeader(
                    onNotificationsTap: () {
                      // TODO: Navigate to notifications
                    },
                    onAvatarTap: () => context.go('/profile'),
                  ).animate().fadeIn(duration: 300.ms),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: QuickActionsGrid(
                  actions: [
                    GymGoQuickActions.reserveClass(
                      () => context.go('/member/classes'),
                    ),
                    GymGoQuickActions.myClasses(
                      () => context.go('/member/classes'),
                      badge: nextClassAsync.valueOrNull != null ? '1' : null,
                    ),
                    GymGoQuickActions.myWorkouts(
                      () => context.go('/member/routines'),
                    ),
                    GymGoQuickActions.addMeasurement(
                      () => context.go('/member/measurements'),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
              ),

              // Admin Tools Card (only for admin/assistant roles)
              if (profileAsync.valueOrNull?.canAccessAdminTools == true)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: GymGoSpacing.screenHorizontal,
                      right: GymGoSpacing.screenHorizontal,
                      top: GymGoSpacing.lg,
                    ),
                    child: AdminToolsCard(
                      role: profileAsync.value!.role,
                      onTap: () => context.push(Routes.adminTools),
                    ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.xl),
              ),

              // Next Class Card - Connected to Supabase
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: nextClassAsync.when(
                    data: (nextClass) {
                      // Calculate duration from start/end time
                      int? duration;
                      DateTime? dateTime;
                      if (nextClass != null) {
                        dateTime = nextClass.date;
                        final startParts = nextClass.startTime.split(':');
                        final endParts = nextClass.endTime.split(':');
                        final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
                        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
                        duration = endMinutes - startMinutes;
                      }

                      return NextClassCard(
                        isLoading: false,
                        className: nextClass?.name,
                        instructorName: nextClass?.instructorName,
                        dateTime: dateTime,
                        duration: duration,
                        onTap: () => context.go('/member/classes'),
                        onCancel: nextClass != null
                            ? () async {
                                await ref.read(classActionsProvider.notifier)
                                    .cancelReservation(nextClass.id);
                                ref.invalidate(nextUserClassProvider);
                              }
                            : null,
                        onReserve: () => context.go('/member/classes'),
                      );
                    },
                    loading: () => NextClassCard(
                      isLoading: true,
                      onTap: () => context.go('/member/classes'),
                      onReserve: () => context.go('/member/classes'),
                    ),
                    error: (_, __) => NextClassCard(
                      isLoading: false,
                      className: null,
                      onTap: () => context.go('/member/classes'),
                      onReserve: () => context.go('/member/classes'),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.md),
              ),

              // Today's Workout Card - Still placeholder (workouts feature not implemented)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: TodayWorkoutCard(
                    isLoading: false,
                    workoutName: null, // Will show empty state
                    exerciseCount: null,
                    estimatedDuration: null,
                    muscleGroups: null,
                    isCompleted: false,
                    onTap: () => context.go('/member/workouts'),
                    onStart: () => context.go('/member/workouts'),
                    onViewAll: () => context.go('/member/workouts'),
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.md),
              ),

              // Last Measurement Card - Connected to Supabase
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: _buildMeasurementCard(context, ref),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.xxl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);

    return memberAsync.when(
      data: (member) {
        if (member == null) {
          return LastMeasurementCard(
            isLoading: false,
            onTap: () => context.go('/member/measurements'),
            onAddMeasurement: () => context.go('/member/measurements'),
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
        }

        final measurementsParams = (memberId: member.id, organizationId: member.organizationId);
        final measurementsAsync = ref.watch(memberMeasurementsProvider(measurementsParams));

        return measurementsAsync.when(
          data: (measurements) {
            if (measurements.isEmpty) {
              return LastMeasurementCard(
                isLoading: false,
                onTap: () => context.go('/member/measurements'),
                onAddMeasurement: () => context.go('/member/measurements'),
              ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
            }

            final latest = measurements.first;
            double? weightChange;

            // Calculate weight change if we have at least 2 measurements
            if (measurements.length > 1 &&
                latest.bodyWeightKg != null &&
                measurements[1].bodyWeightKg != null) {
              weightChange = latest.bodyWeightKg! - measurements[1].bodyWeightKg!;
            }

            return LastMeasurementCard(
              isLoading: false,
              weight: latest.bodyWeightKg,
              bodyFat: latest.bodyFatPercentage,
              muscleMass: latest.muscleMassKg,
              lastMeasuredDate: latest.measuredAt,
              weightChange: weightChange,
              onTap: () => context.go('/member/measurements'),
              onAddMeasurement: () => context.go('/member/measurements'),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms);
          },
          loading: () => LastMeasurementCard(
            isLoading: true,
            onTap: () => context.go('/member/measurements'),
            onAddMeasurement: () => context.go('/member/measurements'),
          ),
          error: (_, __) => LastMeasurementCard(
            isLoading: false,
            onTap: () => context.go('/member/measurements'),
            onAddMeasurement: () => context.go('/member/measurements'),
          ),
        );
      },
      loading: () => LastMeasurementCard(
        isLoading: true,
        onTap: () => context.go('/member/measurements'),
        onAddMeasurement: () => context.go('/member/measurements'),
      ),
      error: (_, __) => LastMeasurementCard(
        isLoading: false,
        onTap: () => context.go('/member/measurements'),
        onAddMeasurement: () => context.go('/member/measurements'),
      ),
    );
  }
}
