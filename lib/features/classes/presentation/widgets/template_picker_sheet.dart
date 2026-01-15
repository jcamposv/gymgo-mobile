import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/class_template.dart';
import '../providers/templates_providers.dart';

/// Bottom sheet for selecting a class template
class TemplatePickerSheet extends ConsumerStatefulWidget {
  const TemplatePickerSheet({
    super.key,
    this.selectedTemplate,
  });

  final ClassTemplate? selectedTemplate;

  static Future<ClassTemplate?> show(
    BuildContext context, {
    ClassTemplate? selectedTemplate,
  }) {
    return showModalBottomSheet<ClassTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymGoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => TemplatePickerSheet(
        selectedTemplate: selectedTemplate,
      ),
    );
  }

  @override
  ConsumerState<TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<TemplatePickerSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(templateSearchQueryProvider.notifier).state = '';
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
        ref.read(templateSearchQueryProvider.notifier).state = value.trim();
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(templateSearchQueryProvider.notifier).state = '';
    setState(() {
      _isSearching = false;
    });
  }

  void _selectTemplate(ClassTemplate template) {
    Navigator.of(context).pop(template);
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
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
                    'Seleccionar Plantilla',
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
                hintText: 'Buscar plantilla...',
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

          // Templates list
          Flexible(
            child: templatesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(GymGoSpacing.xl),
                  child: CircularProgressIndicator(color: GymGoColors.primary),
                ),
              ),
              error: (error, stack) => _buildEmptyState(
                icon: LucideIcons.alertCircle,
                title: 'Error al cargar',
                subtitle: 'No se pudieron cargar las plantillas',
                isError: true,
              ),
              data: (templates) {
                if (templates.isEmpty) {
                  return _buildEmptyState(
                    icon: LucideIcons.layoutTemplate,
                    title: 'Sin plantillas',
                    subtitle: 'No hay plantillas disponibles',
                  );
                }

                // Group templates by day
                final groupedTemplates = _groupByDay(templates);

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
                  itemCount: groupedTemplates.length,
                  itemBuilder: (context, index) {
                    final entry = groupedTemplates.entries.elementAt(index);
                    final dayName = DayOfWeek.getName(entry.key);
                    final dayTemplates = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GymGoSpacing.md,
                            vertical: GymGoSpacing.xs,
                          ),
                          child: Text(
                            dayName,
                            style: GymGoTypography.labelMedium.copyWith(
                              color: GymGoColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Templates for this day
                        ...dayTemplates.map((template) => _TemplateListTile(
                              template: template,
                              onTap: () => _selectTemplate(template),
                              isSelected:
                                  widget.selectedTemplate?.id == template.id,
                            )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<int, List<ClassTemplate>> _groupByDay(List<ClassTemplate> templates) {
    final grouped = <int, List<ClassTemplate>>{};
    for (final template in templates) {
      grouped.putIfAbsent(template.dayOfWeek, () => []).add(template);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
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

/// Template list tile widget
class _TemplateListTile extends StatelessWidget {
  const _TemplateListTile({
    required this.template,
    required this.onTap,
    this.isSelected = false,
  });

  final ClassTemplate template;
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
              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: GymGoSpacing.sm,
                  vertical: GymGoSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: GymGoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: Text(
                  template.startTime,
                  style: GymGoTypography.labelMedium.copyWith(
                    color: GymGoColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),

              // Template info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
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
                    Row(
                      children: [
                        if (template.classType != null) ...[
                          Text(
                            template.classTypeLabel,
                            style: GymGoTypography.labelSmall.copyWith(
                              color: GymGoColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.sm),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: GymGoColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.sm),
                        ],
                        Icon(
                          LucideIcons.users,
                          size: 10,
                          color: GymGoColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.maxCapacity}',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textTertiary,
                          ),
                        ),
                        if (template.instructorName != null) ...[
                          const SizedBox(width: GymGoSpacing.sm),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: GymGoColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: GymGoSpacing.sm),
                          Expanded(
                            child: Text(
                              template.instructorName!,
                              style: GymGoTypography.labelSmall.copyWith(
                                color: GymGoColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

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

/// Compact template chip for showing selected template
class TemplateChip extends StatelessWidget {
  const TemplateChip({
    super.key,
    required this.template,
    this.onTap,
    this.onRemove,
  });

  final ClassTemplate template;
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
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GymGoColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: Icon(
                LucideIcons.layoutTemplate,
                size: 18,
                color: GymGoColors.primary,
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    template.name,
                    style: GymGoTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${template.shortDayName} ${template.timeRange} • ${template.maxCapacity} lugares',
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
