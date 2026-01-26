import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/membership_repository.dart';
import '../../domain/membership_models.dart';

/// Repository provider
final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(Supabase.instance.client);
});

/// Current membership info provider
/// Fetches and caches the user's membership status
final membershipInfoProvider = FutureProvider<MembershipInfo?>((ref) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getMembershipInfo();
});

/// Payment history provider
final paymentHistoryProvider = FutureProvider<List<PaymentRecord>>((ref) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getPaymentHistory();
});

/// Available plans provider
final availablePlansProvider = FutureProvider<List<MembershipPlan>>((ref) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getAvailablePlans();
});

/// Gym contact info provider
final gymContactInfoProvider = FutureProvider<Map<String, String?>>((ref) async {
  final repository = ref.watch(membershipRepositoryProvider);
  return repository.getGymContactInfo();
});

/// Notifier to manage membership state updates
class MembershipNotifier extends AsyncNotifier<MembershipInfo?> {
  @override
  Future<MembershipInfo?> build() async {
    final repository = ref.watch(membershipRepositoryProvider);
    return repository.getMembershipInfo();
  }

  /// Refresh membership info
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(membershipRepositoryProvider);
      return repository.getMembershipInfo();
    });
  }
}

final membershipNotifierProvider =
    AsyncNotifierProvider<MembershipNotifier, MembershipInfo?>(
  MembershipNotifier.new,
);

/// Helper extension for membership status display
extension MembershipStatusDisplay on MembershipStatus {
  String get displayName {
    switch (this) {
      case MembershipStatus.active:
        return 'Activa';
      case MembershipStatus.expiringSoon:
        return 'Por vencer';
      case MembershipStatus.expired:
        return 'Vencida';
      case MembershipStatus.noMembership:
        return 'Sin membresía';
    }
  }

  String get description {
    switch (this) {
      case MembershipStatus.active:
        return 'Tu membresía está activa. Puedes reservar clases.';
      case MembershipStatus.expiringSoon:
        return 'Tu membresía está por vencer. Renueva pronto.';
      case MembershipStatus.expired:
        return 'Tu membresía ha vencido. Renueva para reservar clases.';
      case MembershipStatus.noMembership:
        return 'No tienes membresía activa.';
    }
  }
}
