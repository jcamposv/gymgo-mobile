import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../shared/providers/branding_providers.dart';
import '../../../classes/presentation/providers/classes_providers.dart';
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
                      () => context.go('/member/workouts'),
                    ),
                    GymGoQuickActions.addMeasurement(
                      () => context.go('/member/progress'),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
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

              // Last Measurement Card - Still placeholder (progress feature not implemented)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: LastMeasurementCard(
                    isLoading: false,
                    weight: null, // Will show empty state
                    bodyFat: null,
                    muscleMass: null,
                    lastMeasuredDate: null,
                    weightChange: null,
                    onTap: () => context.go('/member/progress'),
                    onAddMeasurement: () => context.go('/member/progress'),
                  ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
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
}
