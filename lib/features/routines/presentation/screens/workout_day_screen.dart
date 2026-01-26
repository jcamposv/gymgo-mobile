import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/routine.dart';
import '../providers/programs_providers.dart';
import '../widgets/exercise_row.dart';
import '../widgets/exercise_detail_sheet.dart';

/// Screen showing a workout day with exercises and completion flow
class WorkoutDayScreen extends ConsumerStatefulWidget {
  const WorkoutDayScreen({
    super.key,
    required this.workoutId,
  });

  final String workoutId;

  @override
  ConsumerState<WorkoutDayScreen> createState() => _WorkoutDayScreenState();
}

class _WorkoutDayScreenState extends ConsumerState<WorkoutDayScreen> {
  bool _isCompletedToday = false;

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(workoutByIdProvider(widget.workoutId));
    final completeState = ref.watch(completeWorkoutProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, workout);
        },
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(context, error.toString()),
      ),
      bottomNavigationBar: workoutAsync.whenOrNull(
        data: (workout) {
          if (workout == null) return null;
          return _buildBottomBar(context, workout, completeState);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Routine workout) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: GymGoColors.background,
          expandedHeight: 140,
          pinned: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(
              left: GymGoSpacing.screenHorizontal,
              bottom: GymGoSpacing.md,
              right: GymGoSpacing.screenHorizontal,
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workout.dayNumber != null)
                  Text(
                    'Día ${workout.dayNumber}',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  workout.name,
                  style: GymGoTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: GymGoColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    GymGoColors.primary.withValues(alpha: 0.15),
                    GymGoColors.background,
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (_isCompletedToday)
              Container(
                margin: const EdgeInsets.only(right: GymGoSpacing.sm),
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
          ],
        ),

        // Quick stats
        SliverToBoxAdapter(
          child: _buildQuickStats(workout),
        ),

        // Description
        if (workout.description != null && workout.description!.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildDescription(workout.description!),
          ),

        // Exercises header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              GymGoSpacing.screenHorizontal,
              GymGoSpacing.md,
              GymGoSpacing.screenHorizontal,
              GymGoSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ejercicios',
                  style: GymGoTypography.headlineSmall,
                ),
                Text(
                  '${workout.exerciseCount} total',
                  style: GymGoTypography.labelMedium.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Exercise list
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.screenHorizontal,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = workout.exercises[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
                  child: ExerciseRow(
                    exercise: exercise,
                    index: index,
                    onTap: () => _showExerciseDetail(context, exercise, workout.id),
                  ),
                );
              },
              childCount: workout.exercises.length,
            ),
          ),
        ),

        // Bottom spacing for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Routine workout) {
    return Padding(
      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: LucideIcons.list,
              value: '${workout.exerciseCount}',
              label: 'Ejercicios',
            ),
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: LucideIcons.clock,
              value: '~${workout.estimatedDuration}',
              label: 'Minutos',
            ),
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: LucideIcons.repeat,
              value: '${workout.exercises.fold<int>(0, (sum, e) => sum + (e.sets ?? 0))}',
              label: 'Series',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: 20, color: GymGoColors.primary),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            value,
            style: GymGoTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      child: GymGoCard(
        padding: const EdgeInsets.all(GymGoSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.info,
              size: 18,
              color: GymGoColors.textSecondary,
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                description,
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Routine workout,
    AsyncValue<dynamic> completeState,
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
          onPressed: _isCompletedToday || completeState.isLoading
              ? null
              : () => _showCompleteSheet(context, workout),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isCompletedToday ? GymGoColors.success : GymGoColors.primary,
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
                      _isCompletedToday
                          ? LucideIcons.checkCircle
                          : LucideIcons.checkCircle2,
                      size: 20,
                    ),
                    const SizedBox(width: GymGoSpacing.sm),
                    Text(
                      _isCompletedToday
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

  void _showExerciseDetail(
    BuildContext context,
    ExerciseItem exercise,
    String workoutId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(
        exercise: exercise,
        workoutId: workoutId,
      ),
    );
  }

  void _showCompleteSheet(BuildContext context, Routine workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompleteWorkoutSheet(
        workout: workout,
        onComplete: (duration, notes) async {
          final success = await ref
              .read(completeWorkoutProvider.notifier)
              .completeWorkout(
                workout.id,
                durationMinutes: duration,
                notes: notes,
              );

          if (success && mounted) {
            setState(() {
              _isCompletedToday = true;
            });

            // Refresh providers
            refreshProgramProviders(ref, workout.programId);

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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: GymGoColors.primary),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: GymGoColors.error,
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Error al cargar entrenamiento',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error,
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.arrowLeft),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
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
              size: 48,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Entrenamiento no encontrado',
              style: GymGoTypography.headlineSmall,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(LucideIcons.arrowLeft),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for completing a workout
class _CompleteWorkoutSheet extends StatefulWidget {
  const _CompleteWorkoutSheet({
    required this.workout,
    required this.onComplete,
  });

  final Routine workout;
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
    _durationController.text = widget.workout.estimatedDuration.toString();
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
                      widget.workout.name,
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
