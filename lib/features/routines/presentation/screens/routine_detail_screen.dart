import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/routine.dart';
import '../providers/routines_providers.dart';
import '../providers/programs_providers.dart';
import '../widgets/exercise_row.dart';
import '../widgets/exercise_detail_sheet.dart';

/// Screen showing routine details with exercises
class RoutineDetailScreen extends ConsumerStatefulWidget {
  const RoutineDetailScreen({
    super.key,
    required this.routineId,
  });

  final String routineId;

  @override
  ConsumerState<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  bool _isRefreshing = false;
  bool? _localCompletedOverride;

  Future<void> _refreshRoutine() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      // Invalidate the provider to force a fresh fetch
      ref.invalidate(routineByIdProvider(widget.routineId));

      // Wait for the new data
      await ref.read(routineByIdProvider(widget.routineId).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Actualizado'),
              ],
            ),
            backgroundColor: GymGoColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text('Error al actualizar')),
                TextButton(
                  onPressed: _refreshRoutine,
                  child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: GymGoColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineAsync = ref.watch(routineByIdProvider(widget.routineId));
    final completeState = ref.watch(completeWorkoutProvider);
    final completedTodayAsync = ref.watch(workoutCompletedTodayProvider(widget.routineId));

    // Use local override if set, otherwise use database value
    final isCompletedToday = _localCompletedOverride ??
        completedTodayAsync.valueOrNull ?? false;

    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: routineAsync.when(
        data: (routine) {
          if (routine == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, routine, isCompletedToday);
        },
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(context, error),
      ),
      bottomNavigationBar: routineAsync.whenOrNull(
        data: (routine) {
          if (routine == null || !routine.isActive) return null;
          return _buildBottomBar(context, routine, completeState, isCompletedToday);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Routine routine, bool isCompletedToday) {
    return RefreshIndicator(
      onRefresh: _refreshRoutine,
      color: GymGoColors.primary,
      backgroundColor: GymGoColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: GymGoColors.background,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GymGoColors.background.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: const Icon(LucideIcons.arrowLeft, size: 20),
              ),
            ),
            actions: [
              // Completed badge
              if (isCompletedToday)
                Container(
                  margin: const EdgeInsets.only(right: GymGoSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.sm,
                    vertical: GymGoSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        size: 14,
                        color: GymGoColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Refresh button
              IconButton(
                onPressed: _isRefreshing ? null : _refreshRoutine,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GymGoColors.background.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GymGoColors.primary,
                          ),
                        )
                      : const Icon(LucideIcons.refreshCw, size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(routine),
            ),
          ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Quick stats
              _buildQuickStats(routine)
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms),

              const SizedBox(height: GymGoSpacing.lg),

              // Description
              if (routine.description != null &&
                  routine.description!.isNotEmpty) ...[
                _buildDescriptionCard(routine.description!)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 150.ms),
                const SizedBox(height: GymGoSpacing.lg),
              ],

              // WOD info
              if (routine.isWod && routine.wodType != null) ...[
                _buildWodInfo(routine)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms),
                const SizedBox(height: GymGoSpacing.lg),
              ],

              // Exercises section
              _buildSectionHeader('Ejercicios', routine.exerciseCount),
              const SizedBox(height: GymGoSpacing.md),
            ]),
          ),
        ),

        // Exercises list
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.screenHorizontal,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = routine.exercises[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: GymGoSpacing.md),
                  child: ExerciseRow(
                    exercise: exercise,
                    index: index + 1,
                    onTap: () => _showExerciseDetail(context, exercise),
                  ),
                ).animate().fadeIn(
                      duration: 300.ms,
                      delay: Duration(milliseconds: 250 + (index * 50)),
                    );
              },
              childCount: routine.exercises.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: GymGoSpacing.xxl),
        ),
        ],
      ),
    );
  }

  Widget _buildHeader(Routine routine) {
    final color = _getTypeColor(routine.workoutType);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.3),
            GymGoColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.md,
                  vertical: GymGoSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTypeIcon(routine.workoutType),
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      routine.typeDisplay,
                      style: GymGoTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GymGoSpacing.md),

              // Title
              Text(
                routine.name,
                style: GymGoTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Scheduled date
              if (routine.scheduledDate != null) ...[
                const SizedBox(height: GymGoSpacing.sm),
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: GymGoColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatScheduledDate(routine.scheduledDate!),
                      style: GymGoTypography.bodyMedium.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Routine routine) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.listChecks,
            value: routine.exerciseCount.toString(),
            label: 'Ejercicios',
            color: GymGoColors.primary,
          ),
        ),
        const SizedBox(width: GymGoSpacing.md),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.clock,
            value: '~${routine.estimatedDuration}',
            label: 'Minutos',
            color: GymGoColors.info,
          ),
        ),
        const SizedBox(width: GymGoSpacing.md),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.flame,
            value: _getTotalSets(routine).toString(),
            label: 'Series',
            color: const Color(0xFFf97316),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(String description) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.fileText,
                size: 18,
                color: GymGoColors.textTertiary,
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Text(
                'Descripción',
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            description,
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWodInfo(Routine routine) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(GymGoSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFf97316).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: const Icon(
                  LucideIcons.timer,
                  size: 20,
                  color: Color(0xFFf97316),
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.wodType!.label,
                      style: GymGoTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      routine.wodType!.description,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (routine.wodTimeCap != null) ...[
            const SizedBox(height: GymGoSpacing.md),
            Container(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              decoration: BoxDecoration(
                color: GymGoColors.surfaceLight,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 20,
                    color: GymGoColors.warning,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Text(
                    'Time Cap: ${routine.wodTimeCap} minutos',
                    style: GymGoTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GymGoColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: GymGoTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: GymGoColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
          child: Text(
            count.toString(),
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showExerciseDetail(BuildContext context, ExerciseItem exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(
        exercise: exercise,
        workoutId: widget.routineId,
        onExerciseReplaced: () {
          // Refresh the routine to show the new exercise
          ref.invalidate(routineByIdProvider(widget.routineId));
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: GymGoColors.primary),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 64,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Rutina no encontrada',
              style: GymGoTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'Esta rutina no existe o no tienes acceso',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: GymGoColors.error,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Error al cargar',
              style: GymGoTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No se pudo cargar la rutina',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: _refreshRoutine,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Routine routine,
    AsyncValue<dynamic> completeState,
    bool isCompletedToday,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        GymGoSpacing.screenHorizontal,
        GymGoSpacing.md,
        GymGoSpacing.screenHorizontal,
        GymGoSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        border: Border(
          top: BorderSide(color: GymGoColors.cardBorder),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isCompletedToday || completeState.isLoading
              ? null
              : () => _showCompleteSheet(context, routine),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isCompletedToday ? GymGoColors.success : GymGoColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: GymGoColors.success.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
          ),
          child: completeState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCompletedToday
                          ? LucideIcons.checkCircle
                          : LucideIcons.checkCircle2,
                      size: 20,
                    ),
                    const SizedBox(width: GymGoSpacing.sm),
                    Text(
                      isCompletedToday
                          ? 'Entrenamiento completado'
                          : 'Completar entrenamiento',
                      style: GymGoTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showCompleteSheet(BuildContext context, Routine routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteWorkoutSheet(
        routine: routine,
        onComplete: (duration, notes) async {
          final success = await ref
              .read(completeWorkoutProvider.notifier)
              .completeWorkout(
                routine.id,
                durationMinutes: duration,
                notes: notes,
              );

          if (success && mounted) {
            setState(() {
              _localCompletedOverride = true;
            });

            // Refresh providers
            ref.invalidate(workoutCompletedTodayProvider(routine.id));
            ref.invalidate(myRoutinesProvider);

            // Show success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Entrenamiento completado!'),
                backgroundColor: GymGoColors.success,
              ),
            );
          } else if (mounted) {
            final error = ref.read(completeWorkoutProvider).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error?.toString() ?? 'Error al completar'),
                backgroundColor: GymGoColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  int _getTotalSets(Routine routine) {
    return routine.exercises.fold(0, (sum, ex) => sum + (ex.sets ?? 1));
  }

  IconData _getTypeIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.routine:
        return LucideIcons.dumbbell;
      case WorkoutType.wod:
        return LucideIcons.timer;
      case WorkoutType.program:
        return LucideIcons.calendarDays;
    }
  }

  Color _getTypeColor(WorkoutType type) {
    switch (type) {
      case WorkoutType.routine:
        return GymGoColors.primary;
      case WorkoutType.wod:
        return const Color(0xFFf97316);
      case WorkoutType.program:
        return const Color(0xFF8b5cf6);
    }
  }

  String _formatScheduledDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Programado para hoy';
    if (dateOnly == tomorrow) return 'Programado para mañana';

    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];

    return '${days[date.weekday % 7]} ${date.day} de ${months[date.month - 1]}';
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            value,
            style: GymGoTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for completing a workout
class _CompleteWorkoutSheet extends StatefulWidget {
  const _CompleteWorkoutSheet({
    required this.routine,
    required this.onComplete,
  });

  final Routine routine;
  final Future<void> Function(int? duration, String? notes) onComplete;

  @override
  State<_CompleteWorkoutSheet> createState() => _CompleteWorkoutSheetState();
}

class _CompleteWorkoutSheetState extends State<_CompleteWorkoutSheet> {
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with estimated duration
    _durationController.text = widget.routine.estimatedDuration.toString();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        GymGoSpacing.screenHorizontal,
        GymGoSpacing.md,
        GymGoSpacing.screenHorizontal,
        GymGoSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GymGoColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: GymGoSpacing.lg),

          // Title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GymGoColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                ),
                child: const Icon(
                  LucideIcons.checkCircle,
                  color: GymGoColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completar entrenamiento',
                      style: GymGoTypography.headlineSmall,
                    ),
                    Text(
                      widget.routine.name,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: GymGoSpacing.lg),

          // Duration field
          Text(
            'Duración (minutos)',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ej: 45',
              prefixIcon: const Icon(LucideIcons.clock, size: 20),
              filled: true,
              fillColor: GymGoColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: GymGoSpacing.md),

          // Notes field
          Text(
            'Notas (opcional)',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Cómo te sentiste, ajustes de peso, etc.',
              filled: true,
              fillColor: GymGoColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: GymGoSpacing.lg),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Guardar y completar'),
            ),
          ),

          const SizedBox(height: GymGoSpacing.sm),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    final duration = int.tryParse(_durationController.text);
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    await widget.onComplete(duration, notes);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
