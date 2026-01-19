import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../providers/benchmarks_providers.dart';
import '../widgets/pr_list_item.dart';
import '../widgets/pr_history_item.dart';
import '../widgets/add_pr_sheet.dart';
import '../widgets/empty_state.dart';

/// PRs (Personal Records) screen with Current and History tabs
class PRsScreen extends ConsumerStatefulWidget {
  const PRsScreen({super.key});

  @override
  ConsumerState<PRsScreen> createState() => _PRsScreenState();
}

class _PRsScreenState extends ConsumerState<PRsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(prsFilterProvider.notifier).setActiveTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPRSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPRSheet(
        onSuccess: () {
          // Refresh data
          ref.invalidate(currentPRsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(prsFilterProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: GymGoColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: GymGoColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'PRs / Records',
          style: GymGoTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: GymGoColors.primary),
            onPressed: _showAddPRSheet,
            tooltip: 'Agregar PR',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
                vertical: GymGoSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(prsFilterProvider.notifier).setSearchQuery(value);
                },
                style: GymGoTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Buscar ejercicio...',
                  hintStyle: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: GymGoColors.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: filter.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: GymGoColors.textTertiary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(prsFilterProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: GymGoColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.md,
                    vertical: GymGoSpacing.sm,
                  ),
                ),
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
              ),
              decoration: BoxDecoration(
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: GymGoColors.primary,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: GymGoColors.background,
                unselectedLabelColor: GymGoColors.textSecondary,
                labelStyle: GymGoTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GymGoTypography.labelMedium,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Actuales'),
                  Tab(text: 'Historial'),
                ],
              ),
            ),

            const SizedBox(height: GymGoSpacing.md),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CurrentPRsTab(onAddPR: _showAddPRSheet),
                  _HistoryTab(onAddPR: _showAddPRSheet),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPRSheet,
        backgroundColor: GymGoColors.primary,
        foregroundColor: GymGoColors.background,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

/// Current PRs tab content
class _CurrentPRsTab extends ConsumerWidget {
  const _CurrentPRsTab({required this.onAddPR});

  final VoidCallback onAddPR;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(filteredCurrentPRsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentPRsProvider);
      },
      color: GymGoColors.primary,
      backgroundColor: GymGoColors.surface,
      child: prsAsync.when(
        data: (prs) {
          if (prs.isEmpty) {
            return BenchmarkEmptyState(
              icon: LucideIcons.trophy,
              title: 'Sin PRs registrados',
              subtitle: 'Registra tu primer record personal',
              actionLabel: 'Agregar PR',
              onAction: onAddPR,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.screenHorizontal,
            ),
            itemCount: prs.length,
            itemBuilder: (context, index) {
              final pr = prs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
                child: PRListItem(
                  pr: pr,
                  onTap: () {
                    context.push('/benchmarks/prs/${pr.exerciseId}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
        error: (error, _) => BenchmarkEmptyState(
          icon: LucideIcons.alertCircle,
          title: 'Error al cargar',
          subtitle: error.toString(),
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(currentPRsProvider),
        ),
      ),
    );
  }
}

/// History tab content
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.onAddPR});

  final VoidCallback onAddPR;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(prsFilterProvider);
    final params = (
      exerciseId: filter.selectedExerciseId,
      dateFrom: filter.dateFrom,
      dateTo: filter.dateTo,
      page: filter.currentPage,
      pageSize: filter.pageSize,
    );

    final historyAsync = ref.watch(benchmarkHistoryProvider(params));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(benchmarkHistoryProvider(params));
      },
      color: GymGoColors.primary,
      backgroundColor: GymGoColors.surface,
      child: historyAsync.when(
        data: (result) {
          if (result.data.isEmpty) {
            return BenchmarkEmptyState(
              icon: LucideIcons.history,
              title: 'Sin historial',
              subtitle: 'Tus registros aparecerán aquí',
              actionLabel: 'Agregar PR',
              onAction: onAddPR,
            );
          }

          return Column(
            children: [
              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.screenHorizontal,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${result.total} registros',
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                    if (filter.selectedExerciseId != null)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(prsFilterProvider.notifier).setSelectedExercise(null);
                        },
                        icon: const Icon(LucideIcons.x, size: 14),
                        label: const Text('Limpiar filtro'),
                        style: TextButton.styleFrom(
                          foregroundColor: GymGoColors.primary,
                          textStyle: GymGoTypography.labelSmall,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: GymGoSpacing.sm),

              // History list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                  ),
                  itemCount: result.data.length,
                  itemBuilder: (context, index) {
                    final benchmark = result.data[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
                      child: PRHistoryItem(
                        benchmark: benchmark,
                        onTap: () {
                          context.push('/benchmarks/prs/${benchmark.exerciseId}');
                        },
                      ),
                    );
                  },
                ),
              ),

              // Pagination
              if (result.total > filter.pageSize)
                _PaginationControls(
                  currentPage: filter.currentPage,
                  totalPages: (result.total / filter.pageSize).ceil(),
                  onPageChanged: (page) {
                    ref.read(prsFilterProvider.notifier).setPage(page);
                  },
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
        error: (error, _) => BenchmarkEmptyState(
          icon: LucideIcons.alertCircle,
          title: 'Error al cargar',
          subtitle: error.toString(),
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(benchmarkHistoryProvider(params)),
        ),
      ),
    );
  }
}

/// Pagination controls
class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 20),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            color: GymGoColors.textPrimary,
            disabledColor: GymGoColors.textDisabled,
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Text(
            '$currentPage / $totalPages',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(width: GymGoSpacing.sm),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight, size: 20),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            color: GymGoColors.textPrimary,
            disabledColor: GymGoColors.textDisabled,
          ),
        ],
      ),
    );
  }
}
