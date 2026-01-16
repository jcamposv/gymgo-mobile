import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

/// Members list provider
final membersListProvider = FutureProvider<MembersResult>((ref) async {
  final repository = ref.watch(membersRepositoryProvider);
  final query = ref.watch(membersSearchQueryProvider);
  final statusFilter = ref.watch(membersStatusFilterProvider);
  final page = ref.watch(membersPageProvider);

  return repository.getMembers(
    query: query.isEmpty ? null : query,
    status: statusFilter,
    page: page,
    perPage: membersPerPage,
    sortBy: 'created_at',
    ascending: false,
  );
});

/// Search members provider (for autocomplete/quick search)
final membersSearchProvider = FutureProvider.family<List<Member>, String>((ref, query) async {
  if (query.isEmpty) return [];

  final repository = ref.watch(membersRepositoryProvider);
  return repository.searchMembers(query, limit: 10);
});

/// Single member provider
final memberDetailProvider = FutureProvider.family<Member?, String>((ref, id) async {
  final repository = ref.watch(membersRepositoryProvider);
  return repository.getMember(id);
});

/// Total members count provider
final totalMembersCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(membersRepositoryProvider);
  return repository.getTotalMembersCount();
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
