import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../widgets/home_header.dart';
import '../widgets/next_class_card.dart';
import '../widgets/today_workout_card.dart';
import '../widgets/last_measurement_card.dart';
import '../widgets/quick_actions_grid.dart';

/// Home Dashboard Screen with smart cards
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _isLoading = true;

  // Demo data - replace with actual providers
  Map<String, dynamic>? _nextClass;
  Map<String, dynamic>? _todayWorkout;
  Map<String, dynamic>? _lastMeasurement;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate API loading
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;

        // Demo: Show some data, leave others empty to demonstrate empty states
        _nextClass = {
          'name': 'Yoga Flow',
          'instructor': 'María García',
          'dateTime': DateTime.now().add(const Duration(hours: 2)),
          'duration': 60,
        };

        _todayWorkout = {
          'name': 'Full Body Strength',
          'exercises': 8,
          'duration': 45,
          'muscleGroups': ['Pecho', 'Espalda', 'Piernas', 'Core'],
          'isCompleted': false,
        };

        _lastMeasurement = {
          'weight': 75.5,
          'bodyFat': 18.5,
          'muscleMass': 35.2,
          'date': DateTime.now().subtract(const Duration(days: 3)),
          'weightChange': -0.8,
        };
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
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
                    gymName: 'GymGo Fitness',
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
                      badge: _nextClass != null ? '1' : null,
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

              // Next Class Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: NextClassCard(
                    isLoading: _isLoading,
                    className: _nextClass?['name'],
                    instructorName: _nextClass?['instructor'],
                    dateTime: _nextClass?['dateTime'],
                    duration: _nextClass?['duration'],
                    onTap: () => context.go('/member/classes'),
                    onCancel: () {
                      // TODO: Cancel reservation
                    },
                    onReserve: () => context.go('/member/classes'),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.md),
              ),

              // Today's Workout Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: TodayWorkoutCard(
                    isLoading: _isLoading,
                    workoutName: _todayWorkout?['name'],
                    exerciseCount: _todayWorkout?['exercises'],
                    estimatedDuration: _todayWorkout?['duration'],
                    muscleGroups: _todayWorkout?['muscleGroups']?.cast<String>(),
                    isCompleted: _todayWorkout?['isCompleted'] ?? false,
                    onTap: () => context.go('/member/workouts'),
                    onStart: () => context.go('/member/workouts'),
                    onViewAll: () => context.go('/member/workouts'),
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: GymGoSpacing.md),
              ),

              // Last Measurement Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  child: LastMeasurementCard(
                    isLoading: _isLoading,
                    weight: _lastMeasurement?['weight'],
                    bodyFat: _lastMeasurement?['bodyFat'],
                    muscleMass: _lastMeasurement?['muscleMass'],
                    lastMeasuredDate: _lastMeasurement?['date'],
                    weightChange: _lastMeasurement?['weightChange'],
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
