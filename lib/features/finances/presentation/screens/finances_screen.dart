import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/providers/role_providers.dart';
import '../providers/finances_providers.dart';
import '../widgets/payments_list.dart';
import '../widgets/expenses_list.dart';
import '../widgets/income_list.dart';
import '../widgets/finance_overview_card.dart';
import '../widgets/date_range_selector.dart';

/// Main Finances screen with tabs
class FinancesScreen extends ConsumerStatefulWidget {
  const FinancesScreen({super.key});

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tabs = [
      FinanceTab.payments,
      FinanceTab.expenses,
      FinanceTab.income,
      FinanceTab.overview,
    ];
    ref.read(financeTabProvider.notifier).state = tabs[_tabController.index];
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final isAdmin = profileAsync.valueOrNull?.isAdmin ?? false;
    final canAccessFinances = profileAsync.valueOrNull?.canAccessAdminTools ?? false;

    if (!canAccessFinances) {
      return _buildAccessDenied(context);
    }

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Finanzas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: GymGoColors.primary,
          unselectedLabelColor: GymGoColors.textTertiary,
          indicatorColor: GymGoColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            const Tab(text: 'Pagos'),
            const Tab(text: 'Gastos'),
            const Tab(text: 'Ingresos'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Resumen'),
                  if (!isAdmin) ...[
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.lock,
                      size: 12,
                      color: GymGoColors.textTertiary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range selector
          const Padding(
            padding: EdgeInsets.all(GymGoSpacing.md),
            child: DateRangeSelector(),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const PaymentsList(),
                const ExpensesList(),
                const IncomeList(),
                isAdmin
                    ? const FinanceOverviewTab()
                    : _buildAdminOnlyTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Finanzas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: GymGoColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldOff,
                  size: 40,
                  color: GymGoColors.error,
                ),
              ),
              const SizedBox(height: GymGoSpacing.lg),
              Text(
                'Acceso restringido',
                style: GymGoTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GymGoSpacing.sm),
              Text(
                'No tienes permisos para acceder al módulo de finanzas.',
                style: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOnlyTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GymGoColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lock,
                size: 32,
                color: GymGoColors.warning,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              'Solo Administradores',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'El resumen financiero solo está disponible para administradores.',
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

  Widget? _buildFab(BuildContext context) {
    final currentTab = ref.watch(financeTabProvider);

    // No FAB on overview tab
    if (currentTab == FinanceTab.overview) return null;

    String label;
    IconData icon;
    String route;

    switch (currentTab) {
      case FinanceTab.payments:
        label = 'Nuevo Pago';
        icon = LucideIcons.plus;
        route = '/admin/finances/create-payment';
        break;
      case FinanceTab.expenses:
        label = 'Nuevo Gasto';
        icon = LucideIcons.plus;
        route = '/admin/finances/create-expense';
        break;
      case FinanceTab.income:
        label = 'Nuevo Ingreso';
        icon = LucideIcons.plus;
        route = '/admin/finances/create-income';
        break;
      default:
        return null;
    }

    return FloatingActionButton.extended(
      onPressed: () => context.push(route),
      backgroundColor: GymGoColors.primary,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

/// Finance Overview Tab content
class FinanceOverviewTab extends ConsumerWidget {
  const FinanceOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(financeOverviewProvider);

    return overviewAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GymGoColors.primary),
      ),
      error: (error, stack) => Center(
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
              'Error al cargar resumen',
              style: GymGoTypography.bodyLarge.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error.toString(),
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.md),
            ElevatedButton(
              onPressed: () => ref.invalidate(financeOverviewProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (overview) => SingleChildScrollView(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main KPIs
            FinanceOverviewCard(overview: overview),
          ],
        ),
      ),
    );
  }
}
