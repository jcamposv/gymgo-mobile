import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/routine.dart';
import '../providers/routines_providers.dart';
import '../widgets/routine_card.dart';
import '../widgets/routine_filter_chips.dart';

/// Main screen displaying member's assigned routines
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(myRoutinesProvider);
    final filter = ref.watch(routinesFilterProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mis Rutinas',
          style: GymGoTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(myRoutinesProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'Actualizar',
          ),
          const SizedBox(width: GymGoSpacing.sm),
        ],
      ),
      body: RefreshIndicator(
        color: GymGoColors.primary,
        backgroundColor: GymGoColors.cardBackground,
        onRefresh: () async {
          ref.invalidate(myRoutinesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.screenHorizontal,
                  vertical: GymGoSpacing.sm,
                ),
                child: RoutineFilterChips(
                  selectedType: filter.workoutType,
                  onTypeSelected: (type) {
                    ref.read(routinesFilterProvider.notifier).state =
                        filter.copyWith(
                          workoutType: type,
                          clearWorkoutType: type == null,
                        );
                  },
                ),
              ),
            ),

            // Content
            routinesAsync.when(
              data: (routines) {
                // Apply filter
                var filtered = routines;
                if (filter.workoutType != null) {
                  filtered = filtered
                      .where((r) => r.workoutType == filter.workoutType)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(context, filter.workoutType != null),
                  );
                }

                return _buildRoutinesList(context, ref, filtered);
              },
              loading: () => SliverFillRemaining(
                child: _buildLoadingState(),
              ),
              error: (error, _) => SliverFillRemaining(
                child: _buildErrorState(context, ref, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesList(
    BuildContext context,
    WidgetRef ref,
    List<Routine> routines,
  ) {
    // Group by scheduled date
    final grouped = <String, List<Routine>>{};
    for (final routine in routines) {
      final key = routine.scheduledDate != null
          ? _formatDateGroup(routine.scheduledDate!)
          : 'Sin fecha programada';
      grouped.putIfAbsent(key, () => []).add(routine);
    }

    final groups = grouped.entries.toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Calculate which group and item we're at
            int itemCount = 0;
            for (final group in groups) {
              // Group header
              if (index == itemCount) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: itemCount == 0 ? 0 : GymGoSpacing.lg,
                    bottom: GymGoSpacing.sm,
                  ),
                  child: Text(
                    group.key,
                    style: GymGoTypography.labelLarge.copyWith(
                      color: GymGoColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms);
              }
              itemCount++;

              // Group items
              for (int i = 0; i < group.value.length; i++) {
                if (index == itemCount) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: GymGoSpacing.md),
                    child: RoutineCard(
                      routine: group.value[i],
                      onTap: () {
                        final routine = group.value[i];
                        // Bug Fix #3: Navigate to program overview for programs,
                        // routine detail for individual routines/WODs
                        if (routine.isProgram) {
                          context.push('/member/program/${routine.id}');
                        } else {
                          context.push('/member/routines/${routine.id}');
                        }
                      },
                    ),
                  ).animate().fadeIn(
                    duration: 300.ms,
                    delay: Duration(milliseconds: 50 * (index % 10)),
                  );
                }
                itemCount++;
              }
            }
            return null;
          },
          childCount: groups.fold<int>(0, (sum, g) => sum + 1 + g.value.length),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: GymGoSpacing.md),
            child: _RoutineCardSkeleton(),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: GymGoColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusXl),
              ),
              child: Icon(
                LucideIcons.dumbbell,
                size: 48,
                color: GymGoColors.primary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xl),
            Text(
              hasFilter ? 'Sin resultados' : 'Sin rutinas asignadas',
              style: GymGoTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              hasFilter
                  ? 'No hay rutinas que coincidan con el filtro seleccionado'
                  : 'Tu entrenador aún no te ha asignado rutinas.\nContacta con el gimnasio para más información.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: GymGoColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusXl),
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                size: 40,
                color: GymGoColors.error,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Error al cargar rutinas',
              style: GymGoTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No pudimos cargar tus rutinas.\nPor favor intenta de nuevo.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(myRoutinesProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoy';
    if (dateOnly == tomorrow) return 'Mañana';
    if (dateOnly.isBefore(today)) return 'Anteriores';

    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return '${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]}';
  }
}

/// Skeleton loading card
class _RoutineCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(color: GymGoColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: GymGoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 150,
                      decoration: BoxDecoration(
                        color: GymGoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: GymGoColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.md),
          Row(
            children: [
              Container(
                height: 24,
                width: 60,
                decoration: BoxDecoration(
                  color: GymGoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                ),
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: GymGoColors.surfaceLight,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: GymGoColors.cardBorder);
  }
}
