import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/location_providers.dart';
import '../../data/members_repository.dart';
import '../../domain/member.dart';

/// Repository provider
final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(Supabase.instance.client);
});

/// Search query provider
final membersSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected status filter provider
final membersStatusFilterProvider = StateProvider<MemberStatus?>((ref) => null);

/// Current page provider
final membersPageProvider = StateProvider<int>((ref) => 1);

/// Items per page
const int membersPerPage = 20;

/// Members list provider - filtered by admin's active location
final membersListProvider = FutureProvider<MembersResult>((ref) async {
  final repository = ref.watch(membersRepositoryProvider);
  final query = ref.watch(membersSearchQueryProvider);
  final statusFilter = ref.watch(membersStatusFilterProvider);
  final page = ref.watch(membersPageProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.getMembers(
    query: query.isEmpty ? null : query,
    status: statusFilter,
    locationId: locationId,
    page: page,
    perPage: membersPerPage,
    sortBy: 'created_at',
    ascending: false,
  );
});

/// Search members provider (for autocomplete/quick search)
/// Filtered by admin's active location
final membersSearchProvider = FutureProvider.family<List<Member>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final repository = ref.watch(membersRepositoryProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.searchMembers(query, locationId: locationId, limit: 10);
});

/// Single member provider
final memberDetailProvider = FutureProvider.family<Member?, String>((ref, id) async {
  final repository = ref.watch(membersRepositoryProvider);
  return repository.getMember(id);
});

/// Total members count provider - filtered by admin's active location
final totalMembersCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(membersRepositoryProvider);

  // Get active location from admin context
  final activeLocation = await ref.watch(adminActiveLocationProvider.future);
  final locationId = activeLocation?.id;

  return repository.getTotalMembersCount(locationId: locationId);
});

/// Helper to reset filters and go to first page
void resetMembersFilters(WidgetRef ref) {
  ref.read(membersSearchQueryProvider.notifier).state = '';
  ref.read(membersStatusFilterProvider.notifier).state = null;
  ref.read(membersPageProvider.notifier).state = 1;
}

/// Helper to apply search
void searchMembers(WidgetRef ref, String query) {
  ref.read(membersSearchQueryProvider.notifier).state = query;
  ref.read(membersPageProvider.notifier).state = 1;
}

/// Helper to filter by status
void filterMembersByStatus(WidgetRef ref, MemberStatus? status) {
  ref.read(membersStatusFilterProvider.notifier).state = status;
  ref.read(membersPageProvider.notifier).state = 1;
}

/// Helper to go to next page
void nextMembersPage(WidgetRef ref) {
  final currentPage = ref.read(membersPageProvider);
  ref.read(membersPageProvider.notifier).state = currentPage + 1;
}

/// Helper to go to previous page
void previousMembersPage(WidgetRef ref) {
  final currentPage = ref.read(membersPageProvider);
  if (currentPage > 1) {
    ref.read(membersPageProvider.notifier).state = currentPage - 1;
  }
}

/// Helper to refresh members list
void refreshMembers(WidgetRef ref) {
  ref.invalidate(membersListProvider);
}
