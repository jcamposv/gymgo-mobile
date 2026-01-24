import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/location_providers.dart';
import '../../data/finances_repository.dart';
import '../../domain/finance_models.dart';

/// Repository provider
final financesRepositoryProvider = Provider<FinancesRepository>((ref) {
  return FinancesRepository(Supabase.instance.client);
});

// =============================================================================
// FILTER STATE
// =============================================================================

/// Finance tab enum
enum FinanceTab { payments, expenses, income, overview }

/// Current tab state
final financeTabProvider = StateProvider<FinanceTab>((ref) => FinanceTab.payments);

/// Date range filter state
class DateRangeFilter {
  const DateRangeFilter({this.startDate, this.endDate, this.label = 'Este mes'});

  final DateTime? startDate;
  final DateTime? endDate;
  final String label;

  /// Get current month filter
  factory DateRangeFilter.thisMonth() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
      label: 'Este mes',
    );
  }

  /// Get last month filter
  factory DateRangeFilter.lastMonth() {
    final now = DateTime.now();
    return DateRangeFilter(
      startDate: DateTime(now.year, now.month - 1, 1),
      endDate: DateTime(now.year, now.month, 0),
      label: 'Mes pasado',
    );
  }

  /// Get all time filter
  factory DateRangeFilter.allTime() {
    return const DateRangeFilter(label: 'Todo');
  }
}

final dateRangeFilterProvider = StateProvider<DateRangeFilter>((ref) {
  return DateRangeFilter.thisMonth();
});

/// Payment status filter
final paymentStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Expense category filter
final expenseCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Income category filter
final incomeCategoryFilterProvider = StateProvider<String?>((ref) => null);

// =============================================================================
// PAYMENTS PROVIDERS
// =============================================================================

/// Payments list provider - filtered by admin's active location
final paymentsProvider = FutureProvider<PaginatedResult<Payment>>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  final dateRange = ref.watch(dateRangeFilterProvider);
  final status = ref.watch(paymentStatusFilterProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.getPayments(
    status: status,
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    locationId: locationId,
    page: 1,
    perPage: 50,
  );
});

/// Create payment notifier
class CreatePaymentNotifier extends StateNotifier<AsyncValue<Payment?>> {
  CreatePaymentNotifier(this._repository) : super(const AsyncValue.data(null));

  final FinancesRepository _repository;

  Future<bool> createPayment(CreatePaymentDto dto) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repository.createPayment(dto);
      state = AsyncValue.data(payment);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final createPaymentProvider =
    StateNotifierProvider<CreatePaymentNotifier, AsyncValue<Payment?>>((ref) {
  final repository = ref.watch(financesRepositoryProvider);
  return CreatePaymentNotifier(repository);
});

// =============================================================================
// EXPENSES PROVIDERS
// =============================================================================

/// Expenses list provider - filtered by admin's active location
final expensesProvider = FutureProvider<PaginatedResult<Expense>>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  final dateRange = ref.watch(dateRangeFilterProvider);
  final category = ref.watch(expenseCategoryFilterProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.getExpenses(
    category: category,
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    locationId: locationId,
    page: 1,
    perPage: 50,
  );
});

/// Create expense notifier
class CreateExpenseNotifier extends StateNotifier<AsyncValue<Expense?>> {
  CreateExpenseNotifier(this._repository) : super(const AsyncValue.data(null));

  final FinancesRepository _repository;

  Future<bool> createExpense(CreateExpenseDto dto) async {
    state = const AsyncValue.loading();
    try {
      final expense = await _repository.createExpense(dto);
      state = AsyncValue.data(expense);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final createExpenseProvider =
    StateNotifierProvider<CreateExpenseNotifier, AsyncValue<Expense?>>((ref) {
  final repository = ref.watch(financesRepositoryProvider);
  return CreateExpenseNotifier(repository);
});

// =============================================================================
// INCOME PROVIDERS
// =============================================================================

/// Income list provider - filtered by admin's active location
final incomeListProvider = FutureProvider<PaginatedResult<Income>>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  final dateRange = ref.watch(dateRangeFilterProvider);
  final category = ref.watch(incomeCategoryFilterProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.getIncome(
    category: category,
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    locationId: locationId,
    page: 1,
    perPage: 50,
  );
});

/// Create income notifier
class CreateIncomeNotifier extends StateNotifier<AsyncValue<Income?>> {
  CreateIncomeNotifier(this._repository) : super(const AsyncValue.data(null));

  final FinancesRepository _repository;

  Future<bool> createIncome(CreateIncomeDto dto) async {
    state = const AsyncValue.loading();
    try {
      final income = await _repository.createIncome(dto);
      state = AsyncValue.data(income);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final createIncomeProvider =
    StateNotifierProvider<CreateIncomeNotifier, AsyncValue<Income?>>((ref) {
  final repository = ref.watch(financesRepositoryProvider);
  return CreateIncomeNotifier(repository);
});

// =============================================================================
// FINANCE OVERVIEW PROVIDER (Admin only)
// =============================================================================

/// Finance overview provider - filtered by admin's active location
final financeOverviewProvider = FutureProvider<FinanceOverview>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  final dateRange = ref.watch(dateRangeFilterProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.getFinanceOverview(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    locationId: locationId,
  );
});

// =============================================================================
// MEMBERS & PLANS FOR PAYMENT FORM
// =============================================================================

/// Members for payment selection (all members)
final paymentMembersProvider = FutureProvider<List<PaymentMember>>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  return repository.getMembers();
});

/// Plans for payment selection
final paymentPlansProvider = FutureProvider<List<PaymentPlan>>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  return repository.getPlans();
});

// =============================================================================
// MEMBER SEARCH PROVIDERS
// =============================================================================

/// Search query state for member picker
final memberSearchQueryProvider = StateProvider<String>((ref) => '');

/// Member search results provider
/// Searches members by full_name or email using ilike pattern
final memberSearchResultsProvider = FutureProvider<List<PaymentMember>>((ref) async {
  final repository = ref.watch(financesRepositoryProvider);
  final query = ref.watch(memberSearchQueryProvider);

  // If query is empty, return empty list (UI shows recent members instead)
  if (query.isEmpty) {
    return [];
  }

  return repository.searchMembers(
    query: query,
    limit: 25,
    activeOnly: false, // Show all members for payments
  );
});

/// Recent members cache for quick selection
/// Stores last 10 selected members
class RecentMembersNotifier extends StateNotifier<List<PaymentMember>> {
  RecentMembersNotifier() : super([]);

  static const int maxRecent = 10;

  void addMember(PaymentMember member) {
    // Remove if already exists
    final updated = state.where((m) => m.id != member.id).toList();
    // Add to beginning
    updated.insert(0, member);
    // Keep only max recent
    if (updated.length > maxRecent) {
      updated.removeRange(maxRecent, updated.length);
    }
    state = updated;
  }

  void clear() {
    state = [];
  }
}

final recentMembersProvider =
    StateNotifierProvider<RecentMembersNotifier, List<PaymentMember>>((ref) {
  return RecentMembersNotifier();
});

/// Selected member for payment form
final selectedPaymentMemberProvider = StateProvider<PaymentMember?>((ref) => null);
