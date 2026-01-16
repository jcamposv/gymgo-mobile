import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/member.dart';
import '../providers/members_providers.dart';

/// Screen for viewing members list (Admin)
class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      searchMembers(ref, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersListProvider);
    final currentStatusFilter = ref.watch(membersStatusFilterProvider);
    final searchQuery = ref.watch(membersSearchQueryProvider);

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Miembros'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
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
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  hintStyle: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 20,
                    color: GymGoColors.textTertiary,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            searchMembers(ref, '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: GymGoColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    borderSide: const BorderSide(color: GymGoColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    borderSide: const BorderSide(color: GymGoColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                    borderSide: const BorderSide(color: GymGoColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.md,
                    vertical: GymGoSpacing.sm,
                  ),
                ),
              ),
            ),

            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.screenHorizontal,
              ),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Todos',
                    isSelected: currentStatusFilter == null,
                    onTap: () => filterMembersByStatus(ref, null),
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  _buildFilterChip(
                    label: 'Activos',
                    isSelected: currentStatusFilter == MemberStatus.active,
                    onTap: () => filterMembersByStatus(ref, MemberStatus.active),
                    color: GymGoColors.success,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  _buildFilterChip(
                    label: 'Inactivos',
                    isSelected: currentStatusFilter == MemberStatus.inactive,
                    onTap: () => filterMembersByStatus(ref, MemberStatus.inactive),
                    color: GymGoColors.warning,
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  _buildFilterChip(
                    label: 'Suspendidos',
                    isSelected: currentStatusFilter == MemberStatus.suspended,
                    onTap: () => filterMembersByStatus(ref, MemberStatus.suspended),
                    color: GymGoColors.error,
                  ),
                ],
              ),
            ),

            const SizedBox(height: GymGoSpacing.md),

            // Members list
            Expanded(
              child: membersAsync.when(
                data: (result) {
                  if (result.members.isEmpty) {
                    return _buildEmptyState(searchQuery.isNotEmpty);
                  }
                  return _buildMembersList(result.members);
                },
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? GymGoColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.15)
              : GymGoColors.cardBackground,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : GymGoColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GymGoTypography.labelMedium.copyWith(
            color: isSelected ? chipColor : GymGoColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList(List<Member> members) {
    return RefreshIndicator(
      onRefresh: () async {
        refreshMembers(ref);
      },
      color: GymGoColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.screenHorizontal,
        ),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return GymGoCard(
      margin: const EdgeInsets.only(bottom: GymGoSpacing.sm),
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(member.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
            ),
            child: member.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                    child: Image.network(
                      member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitialsAvatar(member),
                    ),
                  )
                : _buildInitialsAvatar(member),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: GymGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.phone != null && member.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.phone!,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status badge
          _buildStatusBadge(member.status),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(Member member) {
    return Center(
      child: Text(
        member.initials,
        style: GymGoTypography.labelMedium.copyWith(
          color: _getStatusColor(member.status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MemberStatus status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.sm,
        vertical: GymGoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: GymGoTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return GymGoColors.success;
      case MemberStatus.inactive:
        return GymGoColors.warning;
      case MemberStatus.suspended:
        return GymGoColors.error;
      case MemberStatus.cancelled:
        return GymGoColors.textTertiary;
    }
  }

  String _getStatusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.inactive:
        return 'Inactivo';
      case MemberStatus.suspended:
        return 'Suspendido';
      case MemberStatus.cancelled:
        return 'Cancelado';
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return GymGoCard(
          margin: const EdgeInsets.only(bottom: GymGoSpacing.sm),
          padding: const EdgeInsets.all(GymGoSpacing.md),
          child: Row(
            children: [
              GymGoShimmerBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GymGoShimmerBox(width: 120, height: 16),
                    const SizedBox(height: 4),
                    GymGoShimmerBox(width: 180, height: 14),
                  ],
                ),
              ),
              GymGoShimmerBox(width: 60, height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
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
                color: GymGoColors.surface,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
              ),
              child: Icon(
                isFiltered ? LucideIcons.searchX : LucideIcons.users,
                size: 36,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              isFiltered ? 'Sin resultados' : 'No hay miembros',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              isFiltered
                  ? 'Intenta con otros terminos de busqueda'
                  : 'Los miembros apareceran aqui cuando se registren',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: GymGoSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  resetMembersFilters(ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.primary,
                  foregroundColor: GymGoColors.background,
                ),
                child: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                size: 36,
                color: GymGoColors.error,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Error al cargar miembros',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              error,
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => refreshMembers(ref),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.primary,
                foregroundColor: GymGoColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple debouncer for search input
class Debouncer {
  Debouncer({required this.milliseconds});

  final int milliseconds;
  VoidCallback? _action;
  bool _isRunning = false;

  void run(VoidCallback action) {
    _action = action;
    if (!_isRunning) {
      _isRunning = true;
      Future.delayed(Duration(milliseconds: milliseconds), () {
        _action?.call();
        _isRunning = false;
      });
    }
  }

  void cancel() {
    _action = null;
    _isRunning = false;
  }
}
