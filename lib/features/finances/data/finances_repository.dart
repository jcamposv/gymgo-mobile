import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/finance_models.dart';

/// Repository for finance operations with Supabase
/// Matches web/src/actions/finance.actions.ts queries exactly
class FinancesRepository {
  FinancesRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Get user's organization ID
  Future<String?> _getOrganizationId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('organization_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['organization_id'] as String?;
    } catch (e) {
      debugPrint('FinancesRepository: Error getting organization ID: $e');
      return null;
    }
  }

  /// Get organization currency
  Future<String> _getOrganizationCurrency(String organizationId) async {
    try {
      final response = await _supabase
          .from('organizations')
          .select('currency')
          .eq('id', organizationId)
          .maybeSingle();

      return response?['currency'] as String? ?? 'MXN';
    } catch (e) {
      debugPrint('FinancesRepository: Error getting currency: $e');
      return 'MXN';
    }
  }

  // ===========================================================================
  // PAYMENTS - Matching web getPayments()
  // ===========================================================================

  /// Get payments with pagination and filters
  /// Matches web query: payments + member + plan + created_by_profile joins
  Future<PaginatedResult<Payment>> getPayments({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    try {
      // Build base query with filters FIRST
      var query = _supabase
          .from('payments')
          .select('''
            *,
            member:members(id, full_name, email),
            plan:membership_plans(id, name),
            created_by_profile:profiles(full_name)
          ''')
          .eq('organization_id', organizationId);

      // Apply filters before order/range
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Then apply order and pagination
      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      // Get total count with same filters
      var countQuery = _supabase
          .from('payments')
          .select('id')
          .eq('organization_id', organizationId);

      if (status != null && status.isNotEmpty) {
        countQuery = countQuery.eq('status', status);
      }
      if (startDate != null) {
        countQuery = countQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        countQuery = countQuery.lte('created_at', endDate.toIso8601String());
      }

      final countResponse = await countQuery;
      final count = (countResponse as List).length;

      final payments = (response as List)
          .map((json) => Payment.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginatedResult(
        data: payments,
        count: count,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      debugPrint('FinancesRepository: Error getting payments: $e');
      rethrow;
    }
  }

  /// Create payment matching web createPayment()
  Future<Payment> createPayment(CreatePaymentDto dto) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final currency = await _getOrganizationCurrency(organizationId);

    try {
      final insertData = {
        ...dto.toJson(),
        'organization_id': organizationId,
        'currency': currency,
        'status': 'paid', // Default to paid like web
        'created_by': userId,
      };

      final response = await _supabase
          .from('payments')
          .insert(insertData)
          .select('''
            *,
            member:members(id, full_name, email),
            plan:membership_plans(id, name),
            created_by_profile:profiles(full_name)
          ''')
          .single();

      // Update member's membership status if plan is included (matching web)
      if (dto.planId != null) {
        await _supabase
            .from('members')
            .update({
              'current_plan_id': dto.planId,
              'membership_status': 'active',
            })
            .eq('id', dto.memberId)
            .eq('organization_id', organizationId);
      }

      return Payment.fromJson(response);
    } catch (e) {
      debugPrint('FinancesRepository: Error creating payment: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // EXPENSES - Matching web getExpenses()
  // ===========================================================================

  /// Get expenses with pagination and filters
  Future<PaginatedResult<Expense>> getExpenses({
    String? category,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    try {
      // Build base query with filters FIRST
      var dbQuery = _supabase
          .from('expenses')
          .select('''
            *,
            created_by_profile:profiles(full_name)
          ''')
          .eq('organization_id', organizationId);

      // Apply filters before order/range
      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.ilike('description', '%$query%');
      }
      if (category != null && category.isNotEmpty) {
        dbQuery = dbQuery.eq('category', category);
      }
      if (startDate != null) {
        dbQuery = dbQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        dbQuery = dbQuery.lte('created_at', endDate.toIso8601String());
      }

      // Then apply order and pagination
      final response = await dbQuery
          .order('created_at', ascending: false)
          .range(from, to);

      // Get count with same filters
      var countQuery = _supabase
          .from('expenses')
          .select('id')
          .eq('organization_id', organizationId);

      if (query != null && query.isNotEmpty) {
        countQuery = countQuery.ilike('description', '%$query%');
      }
      if (category != null && category.isNotEmpty) {
        countQuery = countQuery.eq('category', category);
      }
      if (startDate != null) {
        countQuery = countQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        countQuery = countQuery.lte('created_at', endDate.toIso8601String());
      }

      final countResponse = await countQuery;
      final count = (countResponse as List).length;

      final expenses = (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginatedResult(
        data: expenses,
        count: count,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      debugPrint('FinancesRepository: Error getting expenses: $e');
      rethrow;
    }
  }

  /// Create expense matching web createExpense()
  Future<Expense> createExpense(CreateExpenseDto dto) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final currency = await _getOrganizationCurrency(organizationId);

    try {
      final insertData = {
        ...dto.toJson(),
        'organization_id': organizationId,
        'currency': currency,
        'created_by': userId,
      };

      final response = await _supabase
          .from('expenses')
          .insert(insertData)
          .select('''
            *,
            created_by_profile:profiles(full_name)
          ''')
          .single();

      return Expense.fromJson(response);
    } catch (e) {
      debugPrint('FinancesRepository: Error creating expense: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // INCOME - Matching web getIncome()
  // ===========================================================================

  /// Get income with pagination and filters
  Future<PaginatedResult<Income>> getIncome({
    String? category,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final from = (page - 1) * perPage;
    final to = from + perPage - 1;

    try {
      // Build base query with filters FIRST
      var dbQuery = _supabase
          .from('income')
          .select('''
            *,
            created_by_profile:profiles(full_name)
          ''')
          .eq('organization_id', organizationId);

      // Apply filters before order/range
      if (query != null && query.isNotEmpty) {
        dbQuery = dbQuery.ilike('description', '%$query%');
      }
      if (category != null && category.isNotEmpty) {
        dbQuery = dbQuery.eq('category', category);
      }
      if (startDate != null) {
        dbQuery = dbQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        dbQuery = dbQuery.lte('created_at', endDate.toIso8601String());
      }

      // Then apply order and pagination
      final response = await dbQuery
          .order('created_at', ascending: false)
          .range(from, to);

      // Get count with same filters
      var countQuery = _supabase
          .from('income')
          .select('id')
          .eq('organization_id', organizationId);

      if (query != null && query.isNotEmpty) {
        countQuery = countQuery.ilike('description', '%$query%');
      }
      if (category != null && category.isNotEmpty) {
        countQuery = countQuery.eq('category', category);
      }
      if (startDate != null) {
        countQuery = countQuery.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        countQuery = countQuery.lte('created_at', endDate.toIso8601String());
      }

      final countResponse = await countQuery;
      final count = (countResponse as List).length;

      final incomeList = (response as List)
          .map((json) => Income.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginatedResult(
        data: incomeList,
        count: count,
        page: page,
        perPage: perPage,
      );
    } catch (e) {
      debugPrint('FinancesRepository: Error getting income: $e');
      rethrow;
    }
  }

  /// Create income matching web createIncome()
  Future<Income> createIncome(CreateIncomeDto dto) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final currency = await _getOrganizationCurrency(organizationId);

    try {
      final insertData = {
        ...dto.toJson(),
        'organization_id': organizationId,
        'currency': currency,
        'created_by': userId,
      };

      final response = await _supabase
          .from('income')
          .insert(insertData)
          .select('''
            *,
            created_by_profile:profiles(full_name)
          ''')
          .single();

      return Income.fromJson(response);
    } catch (e) {
      debugPrint('FinancesRepository: Error creating income: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // FINANCE OVERVIEW - Matching web getFinanceOverview()
  // ===========================================================================

  /// Get finance overview (Admin only)
  Future<FinanceOverview> getFinanceOverview({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    final now = DateTime.now();
    final periodStart = startDate ?? DateTime(now.year, now.month, 1);
    final periodEnd = endDate ?? DateTime(now.year, now.month + 1, 0);

    final currency = await _getOrganizationCurrency(organizationId);

    try {
      // Get total payments (membership income) - status = 'paid'
      final paymentsResponse = await _supabase
          .from('payments')
          .select('amount')
          .eq('organization_id', organizationId)
          .eq('status', 'paid')
          .gte('created_at', periodStart.toIso8601String())
          .lte('created_at', periodEnd.toIso8601String());

      final membershipIncome = (paymentsResponse as List)
          .fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

      // Get other income
      final incomeResponse = await _supabase
          .from('income')
          .select('amount')
          .eq('organization_id', organizationId)
          .gte('income_date', periodStart.toIso8601String())
          .lte('income_date', periodEnd.toIso8601String());

      final otherIncome = (incomeResponse as List)
          .fold<double>(0, (sum, i) => sum + (i['amount'] as num).toDouble());

      // Get total expenses
      final expensesResponse = await _supabase
          .from('expenses')
          .select('amount')
          .eq('organization_id', organizationId)
          .gte('expense_date', periodStart.toIso8601String())
          .lte('expense_date', periodEnd.toIso8601String());

      final totalExpenses = (expensesResponse as List)
          .fold<double>(0, (sum, e) => sum + (e['amount'] as num).toDouble());

      // Get pending payments (not filtered by date)
      final pendingResponse = await _supabase
          .from('payments')
          .select('amount')
          .eq('organization_id', organizationId)
          .eq('status', 'pending');

      final pendingPayments = (pendingResponse as List)
          .fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

      final totalIncome = membershipIncome + otherIncome;
      final netProfit = totalIncome - totalExpenses;

      return FinanceOverview(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        membershipIncome: membershipIncome,
        otherIncome: otherIncome,
        pendingPayments: pendingPayments,
        currency: currency,
        periodFrom: periodStart,
        periodTo: periodEnd,
      );
    } catch (e) {
      debugPrint('FinancesRepository: Error getting finance overview: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // MEMBERS & PLANS FOR PAYMENT FORM
  // ===========================================================================

  /// Get members for payment selection (all active members)
  Future<List<PaymentMember>> getMembers() async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    try {
      final response = await _supabase
          .from('members')
          .select('id, full_name, email, phone, avatar_url, status')
          .eq('organization_id', organizationId)
          .order('full_name', ascending: true);

      return (response as List)
          .map((json) => PaymentMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FinancesRepository: Error getting members: $e');
      rethrow;
    }
  }

  /// Search members by name or email (matching web implementation)
  /// Uses ilike with OR pattern: full_name.ilike.%query%,email.ilike.%query%
  Future<List<PaymentMember>> searchMembers({
    required String query,
    int limit = 25,
    bool activeOnly = false,
  }) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    try {
      var dbQuery = _supabase
          .from('members')
          .select('id, full_name, email, phone, avatar_url, status')
          .eq('organization_id', organizationId);

      // Apply search filter using OR pattern matching web
      if (query.isNotEmpty) {
        dbQuery = dbQuery.or('full_name.ilike.%$query%,email.ilike.%$query%');
      }

      // Optionally filter to active members only
      if (activeOnly) {
        dbQuery = dbQuery.eq('status', 'active');
      }

      // Order by full_name and limit results
      final response = await dbQuery
          .order('full_name', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => PaymentMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FinancesRepository: Error searching members: $e');
      rethrow;
    }
  }

  /// Get a single member by ID
  Future<PaymentMember?> getMemberById(String memberId) async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    try {
      final response = await _supabase
          .from('members')
          .select('id, full_name, email, phone, avatar_url, status')
          .eq('organization_id', organizationId)
          .eq('id', memberId)
          .maybeSingle();

      if (response == null) return null;
      return PaymentMember.fromJson(response);
    } catch (e) {
      debugPrint('FinancesRepository: Error getting member by ID: $e');
      rethrow;
    }
  }

  /// Get membership plans for payment selection
  Future<List<PaymentPlan>> getPlans() async {
    final organizationId = await _getOrganizationId();
    if (organizationId == null) {
      throw Exception('No organization found');
    }

    try {
      final response = await _supabase
          .from('membership_plans')
          .select('id, name, price')
          .eq('organization_id', organizationId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => PaymentPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FinancesRepository: Error getting plans: $e');
      rethrow;
    }
  }
}
