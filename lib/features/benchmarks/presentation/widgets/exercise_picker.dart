import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/benchmark.dart';

/// Searchable exercise picker widget
class ExercisePicker extends StatefulWidget {
  const ExercisePicker({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  final List<ExerciseOption> options;
  final ExerciseOption? selectedOption;
  final ValueChanged<ExerciseOption> onSelected;

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  void _showPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePickerSheet(
        options: widget.options,
        selectedOption: widget.selectedOption,
        onSelected: (exercise) {
          widget.onSelected(exercise);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: widget.selectedOption != null
              ? Border.all(color: GymGoColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.selectedOption != null
                    ? GymGoColors.primary.withValues(alpha: 0.1)
                    : GymGoColors.cardBackground,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: Icon(
                LucideIcons.dumbbell,
                color: widget.selectedOption != null
                    ? GymGoColors.primary
                    : GymGoColors.textTertiary,
                size: 18,
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedOption?.displayName ?? 'Seleccionar ejercicio',
                    style: GymGoTypography.bodyMedium.copyWith(
                      color: widget.selectedOption != null
                          ? GymGoColors.textPrimary
                          : GymGoColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.selectedOption?.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.selectedOption!.category!,
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronDown,
              color: GymGoColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for searching and selecting an exercise
class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  final List<ExerciseOption> options;
  final ExerciseOption? selectedOption;
  final ValueChanged<ExerciseOption> onSelected;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  List<ExerciseOption> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredOptions = widget.options.where((option) {
          return option.displayName.toLowerCase().contains(lowerQuery) ||
              (option.category?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group by category
    final groupedOptions = <String?, List<ExerciseOption>>{};
    for (final option in _filteredOptions) {
      groupedOptions.putIfAbsent(option.category, () => []).add(option);
    }

    return Container(
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: GymGoColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: GymGoSpacing.md),

                    // Title
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.dumbbell,
                          color: GymGoColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: GymGoSpacing.sm),
                        Text(
                          'Seleccionar ejercicio',
                          style: GymGoTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GymGoSpacing.md),

                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GymGoTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Buscar ejercicio...',
                        hintStyle: GymGoTypography.bodyMedium.copyWith(
                          color: GymGoColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: GymGoColors.textTertiary,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  LucideIcons.x,
                                  color: GymGoColors.textTertiary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: GymGoColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: GymGoSpacing.md,
                          vertical: GymGoSpacing.sm,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.screenHorizontal,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredOptions.length} ejercicios',
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GymGoSpacing.sm),

              // Exercise list
              Expanded(
                child: _filteredOptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.searchX,
                              size: 48,
                              color: GymGoColors.textTertiary,
                            ),
                            const SizedBox(height: GymGoSpacing.md),
                            Text(
                              'No se encontraron ejercicios',
                              style: GymGoTypography.bodyMedium.copyWith(
                                color: GymGoColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: GymGoSpacing.screenHorizontal,
                        ),
                        itemCount: _filteredOptions.length,
                        itemBuilder: (context, index) {
                          final option = _filteredOptions[index];
                          final isSelected = widget.selectedOption?.id == option.id;

                          // Category header
                          Widget? header;
                          if (index == 0 ||
                              _filteredOptions[index - 1].category != option.category) {
                            header = Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : GymGoSpacing.md,
                                bottom: GymGoSpacing.xs,
                              ),
                              child: Text(
                                option.category ?? 'Sin categoría',
                                style: GymGoTypography.labelMedium.copyWith(
                                  color: GymGoColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (header != null) header,
                              GestureDetector(
                                onTap: () => widget.onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.all(GymGoSpacing.sm),
                                  margin: const EdgeInsets.only(bottom: GymGoSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? GymGoColors.primary.withValues(alpha: 0.1)
                                        : GymGoColors.surface,
                                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                                    border: isSelected
                                        ? Border.all(color: GymGoColors.primary)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option.displayName,
                                          style: GymGoTypography.bodyMedium.copyWith(
                                            color: isSelected
                                                ? GymGoColors.primary
                                                : GymGoColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          LucideIcons.check,
                                          color: GymGoColors.primary,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
