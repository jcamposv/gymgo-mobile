/// Finance domain models matching web/src/actions/finance.actions.ts

// =============================================================================
// ENUMS
// =============================================================================

/// Payment method enum matching web
enum PaymentMethod {
  cash('cash', 'Efectivo'),
  card('card', 'Tarjeta'),
  transfer('transfer', 'Transferencia'),
  other('other', 'Otro');

  const PaymentMethod(this.value, this.label);
  final String value;
  final String label;

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Payment status enum matching web
enum PaymentStatus {
  paid('paid', 'Pagado'),
  pending('pending', 'Pendiente'),
  failed('failed', 'Fallido'),
  refunded('refunded', 'Reembolsado');

  const PaymentStatus(this.value, this.label);
  final String value;
  final String label;

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Expense category enum matching web
enum ExpenseCategory {
  rent('rent', 'Renta'),
  utilities('utilities', 'Servicios'),
  salaries('salaries', 'Salarios'),
  equipment('equipment', 'Equipo'),
  maintenance('maintenance', 'Mantenimiento'),
  marketing('marketing', 'Marketing'),
  supplies('supplies', 'Insumos'),
  insurance('insurance', 'Seguros'),
  taxes('taxes', 'Impuestos'),
  other('other', 'Otro');

  const ExpenseCategory(this.value, this.label);
  final String value;
  final String label;

  static ExpenseCategory fromString(String? value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Income category enum matching web
enum IncomeCategory {
  productSale('product_sale', 'Venta de producto'),
  service('service', 'Servicio'),
  rental('rental', 'Alquiler'),
  event('event', 'Evento'),
  donation('donation', 'Donación'),
  other('other', 'Otro');

  const IncomeCategory(this.value, this.label);
  final String value;
  final String label;

  static IncomeCategory fromString(String? value) {
    return IncomeCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => IncomeCategory.other,
    );
  }
}

// =============================================================================
// PAYMENT MODEL
// =============================================================================

/// Payment model matching web Payment interface
class Payment {
  const Payment({
    required this.id,
    required this.organizationId,
    required this.memberId,
    this.planId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.paymentDate,
    required this.status,
    this.notes,
    this.referenceNumber,
    required this.createdBy,
    required this.createdAt,
    this.memberName,
    this.memberEmail,
    this.planName,
    this.createdByName,
  });

  final String id;
  final String organizationId;
  final String memberId;
  final String? planId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final DateTime? paymentDate;
  final PaymentStatus status;
  final String? notes;
  final String? referenceNumber;
  final String createdBy;
  final DateTime createdAt;
  // Joined fields
  final String? memberName;
  final String? memberEmail;
  final String? planName;
  final String? createdByName;

  factory Payment.fromJson(Map<String, dynamic> json) {
    // Handle nested member data
    final member = json['member'] as Map<String, dynamic>?;
    final plan = json['plan'] as Map<String, dynamic>?;
    final createdByProfile = json['created_by_profile'] as Map<String, dynamic>?;

    return Payment(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      memberId: json['member_id'] as String,
      planId: json['plan_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      paymentMethod: PaymentMethod.fromString(json['payment_method'] as String?),
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String)
          : null,
      status: PaymentStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      referenceNumber: json['reference_number'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      memberName: member?['full_name'] as String?,
      memberEmail: member?['email'] as String?,
      planName: plan?['name'] as String?,
      createdByName: createdByProfile?['full_name'] as String?,
    );
  }
}

// =============================================================================
// EXPENSE MODEL
// =============================================================================

/// Expense model matching web Expense interface
class Expense {
  const Expense({
    required this.id,
    required this.organizationId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    this.expenseDate,
    this.vendor,
    this.receiptUrl,
    this.notes,
    required this.isRecurring,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
  });

  final String id;
  final String organizationId;
  final String description;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final DateTime? expenseDate;
  final String? vendor;
  final String? receiptUrl;
  final String? notes;
  final bool isRecurring;
  final String createdBy;
  final DateTime createdAt;
  final String? createdByName;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final createdByProfile = json['created_by_profile'] as Map<String, dynamic>?;

    return Expense(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      category: ExpenseCategory.fromString(json['category'] as String?),
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : null,
      vendor: json['vendor'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      notes: json['notes'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByName: createdByProfile?['full_name'] as String?,
    );
  }
}

// =============================================================================
// INCOME MODEL
// =============================================================================

/// Income model matching web Income interface
class Income {
  const Income({
    required this.id,
    required this.organizationId,
    required this.description,
    required this.amount,
    required this.currency,
    required this.category,
    this.incomeDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
  });

  final String id;
  final String organizationId;
  final String description;
  final double amount;
  final String currency;
  final IncomeCategory category;
  final DateTime? incomeDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final String? createdByName;

  factory Income.fromJson(Map<String, dynamic> json) {
    final createdByProfile = json['created_by_profile'] as Map<String, dynamic>?;

    return Income(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      category: IncomeCategory.fromString(json['category'] as String?),
      incomeDate: json['income_date'] != null
          ? DateTime.parse(json['income_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      createdByName: createdByProfile?['full_name'] as String?,
    );
  }
}

// =============================================================================
// FINANCE OVERVIEW MODEL
// =============================================================================

/// Finance overview model matching web FinanceOverview interface
class FinanceOverview {
  const FinanceOverview({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.membershipIncome,
    required this.otherIncome,
    required this.pendingPayments,
    required this.currency,
    required this.periodFrom,
    required this.periodTo,
  });

  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double membershipIncome;
  final double otherIncome;
  final double pendingPayments;
  final String currency;
  final DateTime periodFrom;
  final DateTime periodTo;

  factory FinanceOverview.empty() {
    return FinanceOverview(
      totalIncome: 0,
      totalExpenses: 0,
      netProfit: 0,
      membershipIncome: 0,
      otherIncome: 0,
      pendingPayments: 0,
      currency: 'MXN',
      periodFrom: DateTime.now(),
      periodTo: DateTime.now(),
    );
  }
}

// =============================================================================
// MEMBER FOR PAYMENT SELECTION
// =============================================================================

/// Member for payment selection with enhanced fields for search
class PaymentMember {
  const PaymentMember({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? status;

  /// Get first name (first word of full name)
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Get last name (everything after first word)
  String get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Get initials for avatar placeholder
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  factory PaymentMember.fromJson(Map<String, dynamic> json) {
    return PaymentMember(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Membership plan for payment selection
class PaymentPlan {
  const PaymentPlan({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

// =============================================================================
// CREATE DTOs
// =============================================================================

/// DTO for creating a payment
class CreatePaymentDto {
  const CreatePaymentDto({
    required this.memberId,
    this.planId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    this.referenceNumber,
  });

  final String memberId;
  final String? planId;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final String? referenceNumber;

  Map<String, dynamic> toJson() {
    return {
      'member_id': memberId,
      if (planId != null) 'plan_id': planId,
      'amount': amount,
      'payment_method': paymentMethod.value,
      'payment_date': paymentDate.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (referenceNumber != null && referenceNumber!.isNotEmpty)
        'reference_number': referenceNumber,
    };
  }
}

/// DTO for creating an expense
class CreateExpenseDto {
  const CreateExpenseDto({
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    this.vendor,
    this.receiptUrl,
    this.notes,
    this.isRecurring = false,
  });

  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime expenseDate;
  final String? vendor;
  final String? receiptUrl;
  final String? notes;
  final bool isRecurring;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category': category.value,
      'expense_date': expenseDate.toIso8601String(),
      if (vendor != null && vendor!.isNotEmpty) 'vendor': vendor,
      if (receiptUrl != null && receiptUrl!.isNotEmpty) 'receipt_url': receiptUrl,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'is_recurring': isRecurring,
    };
  }
}

/// DTO for creating income
class CreateIncomeDto {
  const CreateIncomeDto({
    required this.description,
    required this.amount,
    required this.category,
    required this.incomeDate,
    this.notes,
  });

  final String description;
  final double amount;
  final IncomeCategory category;
  final DateTime incomeDate;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'category': category.value,
      'income_date': incomeDate.toIso8601String(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

// =============================================================================
// PAGINATED RESULT
// =============================================================================

/// Paginated result wrapper
class PaginatedResult<T> {
  const PaginatedResult({
    required this.data,
    required this.count,
    required this.page,
    required this.perPage,
  });

  final List<T> data;
  final int count;
  final int page;
  final int perPage;

  int get totalPages => (count / perPage).ceil();
  bool get hasMore => page < totalPages;
}
