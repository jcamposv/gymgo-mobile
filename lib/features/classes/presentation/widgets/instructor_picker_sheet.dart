import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/class_template.dart';
import '../providers/templates_providers.dart';

/// Bottom sheet for selecting an instructor
class InstructorPickerSheet extends ConsumerStatefulWidget {
  const InstructorPickerSheet({
    super.key,
    this.selectedInstructor,
  });

  final Instructor? selectedInstructor;

  static Future<Instructor?> show(
    BuildContext context, {
    Instructor? selectedInstructor,
  }) {
    return showModalBottomSheet<Instructor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymGoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => InstructorPickerSheet(
        selectedInstructor: selectedInstructor,
      ),
    );
  }

  @override
  ConsumerState<InstructorPickerSheet> createState() =>
      _InstructorPickerSheetState();
}

class _InstructorPickerSheetState extends ConsumerState<InstructorPickerSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(instructorSearchQueryProvider.notifier).state = '';
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
    _debounceTimer?.cancel();
    setState(() {
      _isSearching = value.isNotEmpty;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(instructorSearchQueryProvider.notifier).state = value.trim();
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(instructorSearchQueryProvider.notifier).state = '';
    setState(() {
      _isSearching = false;
    });
  }

  void _selectInstructor(Instructor instructor) {
    ref.read(recentInstructorsProvider.notifier).addInstructor(instructor);
    Navigator.of(context).pop(instructor);
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(instructorSearchQueryProvider);
    final searchResults = ref.watch(instructorSearchResultsProvider);
    final recentInstructors = ref.watch(recentInstructorsProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

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
                    'Seleccionar Instructor',
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

          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.md),
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

          // Results
          Flexible(
            child: searchQuery.isEmpty
                ? _buildRecentAndAll(recentInstructors)
                : _buildSearchResults(searchResults),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAndAll(List<Instructor> recentInstructors) {
    final allInstructors = ref.watch(instructorsProvider);

    return allInstructors.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(GymGoSpacing.xl),
          child: CircularProgressIndicator(color: GymGoColors.primary),
        ),
      ),
      error: (error, stack) => _buildEmptyState(
        icon: LucideIcons.alertCircle,
        title: 'Error al cargar',
        subtitle: 'No se pudieron cargar los instructores',
        isError: true,
      ),
      data: (instructors) {
        if (instructors.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.users,
            title: 'Sin instructores',
            subtitle: 'No hay instructores disponibles',
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
          children: [
            // Recent instructors
            if (recentInstructors.isNotEmpty) ...[
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
              ...recentInstructors.map((instructor) => _InstructorListTile(
                    instructor: instructor,
                    onTap: () => _selectInstructor(instructor),
                    isSelected:
                        widget.selectedInstructor?.id == instructor.id,
                  )),
              const SizedBox(height: GymGoSpacing.sm),
            ],

            // All instructors
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.md,
                vertical: GymGoSpacing.xs,
              ),
              child: Text(
                'Todos',
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ),
            ...instructors.map((instructor) => _InstructorListTile(
                  instructor: instructor,
                  onTap: () => _selectInstructor(instructor),
                  isSelected: widget.selectedInstructor?.id == instructor.id,
                )),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Instructor>> searchResults) {
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
      data: (instructors) {
        if (instructors.isEmpty) {
          return _buildEmptyState(
            icon: LucideIcons.userX,
            title: 'Sin resultados',
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
                '${instructors.length} resultado${instructors.length == 1 ? '' : 's'}',
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
                itemCount: instructors.length,
                itemBuilder: (context, index) {
                  final instructor = instructors[index];
                  return _InstructorListTile(
                    instructor: instructor,
                    onTap: () => _selectInstructor(instructor),
                    isSelected:
                        widget.selectedInstructor?.id == instructor.id,
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

/// Instructor list tile widget
class _InstructorListTile extends StatelessWidget {
  const _InstructorListTile({
    required this.instructor,
    required this.onTap,
    this.isSelected = false,
  });

  final Instructor instructor;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          isSelected ? GymGoColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // Avatar
              _InstructorAvatar(instructor: instructor),
              const SizedBox(width: GymGoSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.displayName,
                      style: GymGoTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? GymGoColors.primary
                            : GymGoColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instructor.email,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Role badge
              if (instructor.role != null) ...[
                const SizedBox(width: GymGoSpacing.sm),
                _RoleBadge(role: instructor.role!),
              ],

              // Selection indicator
              if (isSelected) ...[
                const SizedBox(width: GymGoSpacing.sm),
                Icon(
                  LucideIcons.checkCircle2,
                  size: 20,
                  color: GymGoColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Instructor avatar
class _InstructorAvatar extends StatelessWidget {
  const _InstructorAvatar({required this.instructor});

  final Instructor instructor;

  @override
  Widget build(BuildContext context) {
    if (instructor.avatarUrl != null && instructor.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(instructor.avatarUrl!),
        backgroundColor: GymGoColors.surface,
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: GymGoColors.primary.withValues(alpha: 0.15),
      child: Text(
        instructor.initials,
        style: GymGoTypography.labelMedium.copyWith(
          color: GymGoColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Role badge
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: GymGoColors.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getRoleLabel(role),
        style: GymGoTypography.labelSmall.copyWith(
          color: GymGoColors.info,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'instructor':
        return 'Instructor';
      case 'trainer':
        return 'Entrenador';
      case 'assistant':
        return 'Asistente';
      default:
        return role;
    }
  }
}

/// Compact instructor chip for showing selected instructor
class InstructorChip extends StatelessWidget {
  const InstructorChip({
    super.key,
    required this.instructor,
    this.onTap,
    this.onRemove,
  });

  final Instructor instructor;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(GymGoSpacing.sm),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder),
        ),
        child: Row(
          children: [
            // Small avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: GymGoColors.primary.withValues(alpha: 0.15),
              backgroundImage: instructor.avatarUrl != null &&
                      instructor.avatarUrl!.isNotEmpty
                  ? NetworkImage(instructor.avatarUrl!)
                  : null,
              child: instructor.avatarUrl == null || instructor.avatarUrl!.isEmpty
                  ? Text(
                      instructor.initials,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: GymGoSpacing.sm),

            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instructor.displayName,
                    style: GymGoTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    instructor.email,
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Actions
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(LucideIcons.x),
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                color: GymGoColors.textTertiary,
              )
            else if (onTap != null) ...[
              const SizedBox(width: GymGoSpacing.xs),
              Text(
                'Cambiar',
                style: GymGoTypography.labelSmall.copyWith(
                  color: GymGoColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: GymGoColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
