/// Domain models for membership feature
/// Matches web types from membership.actions.ts

import 'package:flutter/foundation.dart';

/// Membership status enum matching database
enum MembershipStatus {
  active,
  expiringSoon, // expiring_soon
  expired,
  noMembership, // no_membership
}

extension MembershipStatusExtension on MembershipStatus {
  String get value {
    switch (this) {
      case MembershipStatus.active:
        return 'active';
      case MembershipStatus.expiringSoon:
        return 'expiring_soon';
      case MembershipStatus.expired:
        return 'expired';
      case MembershipStatus.noMembership:
        return 'no_membership';
    }
  }

  static MembershipStatus fromString(String value) {
    switch (value) {
      case 'active':
        return MembershipStatus.active;
      case 'expiring_soon':
        return MembershipStatus.expiringSoon;
      case 'expired':
        return MembershipStatus.expired;
      case 'no_membership':
        return MembershipStatus.noMembership;
      default:
        return MembershipStatus.noMembership;
    }
  }
}

/// Member's current membership information
@immutable
class MembershipInfo {
  const MembershipInfo({
    required this.memberId,
    required this.memberName,
    required this.status,
    this.planId,
    this.planName,
    this.startDate,
    this.endDate,
    this.daysRemaining,
    this.canBook = false,
  });

  final String memberId;
  final String memberName;
  final MembershipStatus status;
  final String? planId;
  final String? planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? daysRemaining;
  final bool canBook;

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      memberId: json['member_id'] as String? ?? json['id'] as String,
      memberName: json['member_name'] as String? ?? json['full_name'] as String? ?? '',
      status: MembershipStatusExtension.fromString(
        json['membership_status'] as String? ?? 'no_membership',
      ),
      planId: json['current_plan_id'] as String?,
      planName: json['plan_name'] as String? ?? json['plan']?['name'] as String?,
      startDate: json['membership_start_date'] != null
          ? DateTime.tryParse(json['membership_start_date'] as String)
          : null,
      endDate: json['membership_end_date'] != null
          ? DateTime.tryParse(json['membership_end_date'] as String)
          : null,
      daysRemaining: json['days_remaining'] as int?,
      canBook: json['can_book'] as bool? ?? (json['membership_status'] == 'active'),
    );
  }

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'member_name': memberName,
        'membership_status': status.value,
        'current_plan_id': planId,
        'plan_name': planName,
        'membership_start_date': startDate?.toIso8601String(),
        'membership_end_date': endDate?.toIso8601String(),
        'days_remaining': daysRemaining,
        'can_book': canBook,
      };

  MembershipInfo copyWith({
    String? memberId,
    String? memberName,
    MembershipStatus? status,
    String? planId,
    String? planName,
    DateTime? startDate,
    DateTime? endDate,
    int? daysRemaining,
    bool? canBook,
  }) {
    return MembershipInfo(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      status: status ?? this.status,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      canBook: canBook ?? this.canBook,
    );
  }
}

/// Payment record for payment history
@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.planId,
    this.planName,
    this.paymentMethod,
    this.notes,
    this.receiptUrl,
  });

  final String id;
  final double amount;
  final String currency;
  final String status; // paid, pending, cancelled, refunded
  final DateTime createdAt;
  final String? planId;
  final String? planName;
  final String? paymentMethod;
  final String? notes;
  final String? receiptUrl;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      status: json['status'] as String? ?? 'paid',
      createdAt: DateTime.parse(json['created_at'] as String),
      planId: json['plan_id'] as String?,
      planName: json['plan']?['name'] as String? ?? json['plan_name'] as String?,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'plan_id': planId,
        'plan_name': planName,
        'payment_method': paymentMethod,
        'notes': notes,
        'receipt_url': receiptUrl,
      };
}

/// Membership plan info
@immutable
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    this.durationDays,
    this.description,
    this.features,
    this.isActive = true,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final int? durationDays;
  final String? description;
  final List<String>? features;
  final bool isActive;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      durationDays: json['duration_days'] as int?,
      description: json['description'] as String?,
      features: (json['features'] as List?)?.cast<String>(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'currency': currency,
        'duration_days': durationDays,
        'description': description,
        'features': features,
        'is_active': isActive,
      };
}

/// Exception thrown when membership is expired and action is blocked
class MembershipExpiredException implements Exception {
  const MembershipExpiredException([this.message]);

  final String? message;

  @override
  String toString() =>
      message ?? 'Tu membresía ha vencido. Renueva para continuar.';
}
