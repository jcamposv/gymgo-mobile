import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/finance_models.dart';
import '../providers/finances_providers.dart';
import 'member_list_tile.dart';

/// Bottom sheet for searching and selecting a member
class MemberPickerSheet extends ConsumerStatefulWidget {
  const MemberPickerSheet({
    super.key,
    this.selectedMember,
  });

  final PaymentMember? selectedMember;

  /// Show the member picker sheet and return selected member
  static Future<PaymentMember?> show(
    BuildContext context, {
    PaymentMember? selectedMember,
  }) {
    return showModalBottomSheet<PaymentMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymGoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => MemberPickerSheet(
        selectedMember: selectedMember,
      ),
    );
  }

  @override
  ConsumerState<MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends ConsumerState<MemberPickerSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Clear previous search when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberSearchQueryProvider.notifier).state = '';
      // Autofocus on search field
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    setState(() {
      _isSearching = value.isNotEmpty;
    });

    // Debounce search by 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(memberSearchQueryProvider.notifier).state = value.trim();
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(memberSearchQueryProvider.notifier).state = '';
    setState(() {
      _isSearching = false;
    });
  }

  void _selectMember(PaymentMember member) {
    // Add to recent members
    ref.read(recentMembersProvider.notifier).addMember(member);
    // Return selected member
    Navigator.of(context).pop(member);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(memberSearchQueryProvider);
    final searchResults = ref.watch(memberSearchResultsProvider);
    final recentMembers = ref.watch(recentMembersProvider);

    // Calculate max height (90% of screen)
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: GymGoSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GymGoColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Seleccionar miembro',
                    style: GymGoTypography.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x),
                  iconSize: 20,
                  color: GymGoColors.textSecondary,
                ),
              ],
            ),
          ),

          // Search input (pinned)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: GymGoTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                hintStyle: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textTertiary,
                ),
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GymGoColors.primary,
                          ),
                        ),
                      )
                    : Icon(
                        LucideIcons.search,
                        color: GymGoColors.textTertiary,
                        size: 20,
                      ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(LucideIcons.x),
                        iconSize: 18,
                        color: GymGoColors.textTertiary,
                      )
                    : null,
                filled: true,
                fillColor: GymGoColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.md,
                  vertical: GymGoSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  borderSide: BorderSide(color: GymGoColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  borderSide: BorderSide(color: GymGoColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  borderSide: const BorderSide(color: GymGoColors.primary),
                ),
              ),
            ),
          ),

          const SizedBox(height: GymGoSpacing.sm),

          // Results list
          Flexible(
            child: searchQuery.isEmpty
                ? _buildRecentMembers(recentMembers)
                : _buildSearchResults(searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMembers(List<PaymentMember> recentMembers) {
    if (recentMembers.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.search,
        title: 'Busca un miembro',
        subtitle: 'Escribe el nombre o email para buscar',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.xs,
          ),
          child: Text(
            'Recientes',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
            itemCount: recentMembers.length,
            itemBuilder: (context, index) {
              final member = recentMembers[index];
              return MemberListTile(
                member: member,
                onTap: () => _selectMember(member),
                isSelected: widget.selectedMember?.id == member.id,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(AsyncValue<List<PaymentMember>> searchResults) {
    return searchResults.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(GymGoSpacing.xl),
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
      ),
      error: (error, stack) => _buildEmptyState(
        icon: LucideIcons.alertCircle,
        title: 'Error al buscar',
        subtitle: 'Intenta de nuevo',
        isError: true,
      ),
      data: (members) {
        if (members.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.userX,
            title: 'No se encontraron miembros',
            subtitle: 'Prueba con otro nombre o email',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.md,
                vertical: GymGoSpacing.xs,
              ),
              child: Text(
                '${members.length} resultado${members.length == 1 ? '' : 's'}',
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return MemberListTile(
                    member: member,
                    onTap: () => _selectMember(member),
                    isSelected: widget.selectedMember?.id == member.id,
                    showPhone: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isError
                    ? GymGoColors.error.withValues(alpha: 0.1)
                    : GymGoColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isError ? GymGoColors.error : GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              title,
              style: GymGoTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.xs),
            Text(
              subtitle,
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
