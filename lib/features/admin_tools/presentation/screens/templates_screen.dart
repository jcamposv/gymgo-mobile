import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/rbac/rbac.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/providers/role_providers.dart';
import '../../../../shared/ui/components/components.dart';
import '../../../classes/domain/class_template.dart';
import '../../../classes/presentation/providers/templates_providers.dart';
import '../../../classes/presentation/widgets/generate_classes_sheet.dart';
import 'create_template_screen.dart';
import 'edit_template_screen.dart';

/// Screen for managing class templates
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(templateSearchQueryProvider.notifier).state = value;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(templateSearchQueryProvider.notifier).state = '';
  }

  void _createTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTemplateScreen(),
      ),
    );
  }

  Future<void> _generateClasses() async {
    final result = await GenerateClassesSheet.show(context);

    if (result != null && result.success && mounted) {
      // Clear any existing snackbars first
      ScaffoldMessenger.of(context).clearSnackBars();

      // Build message with errors if any
      String message = result.message;
      if (result.hasErrors) {
        message += '\n(${result.errors.length} advertencias)';
      }

      // Show single success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: GymGoColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(GymGoSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
        ),
      );

      // Refresh templates list
      ref.invalidate(templatesProvider);
    }
  }

  void _editTemplate(ClassTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTemplateScreen(templateId: template.id),
      ),
    );
  }

  Future<void> _deleteTemplate(ClassTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GymGoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GymGoColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: GymGoColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(
                'Eliminar plantilla',
                style: GymGoTypography.headlineSmall,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'Se eliminará la plantilla "${template.name}". Las clases ya generadas no serán afectadas.',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GymGoTypography.labelMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GymGoColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(deleteTemplateProvider.notifier).deleteTemplate(
                template.id,
              );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Plantilla eliminada correctamente'
                  : 'Error al eliminar la plantilla',
            ),
            backgroundColor: success ? GymGoColors.success : GymGoColors.error,
          ),
        );
      }
    }
  }

  void _showTemplateActions(ClassTemplate template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GymGoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: GymGoColors.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(GymGoSpacing.radiusSm),
                    ),
                    child: Icon(
                      LucideIcons.layoutTemplate,
                      size: 20,
                      color: GymGoColors.primary,
                    ),
                  ),
                  const SizedBox(width: GymGoSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: GymGoTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${template.dayName} ${template.timeRange}',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Actions
            ListTile(
              leading: const Icon(LucideIcons.pencil, size: 20),
              title: const Text('Editar plantilla'),
              onTap: () {
                Navigator.of(context).pop();
                _editTemplate(template);
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.trash2,
                size: 20,
                color: GymGoColors.error,
              ),
              title: Text(
                'Eliminar plantilla',
                style: TextStyle(color: GymGoColors.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteTemplate(template);
              },
            ),
            const SizedBox(height: GymGoSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesProvider);
    final canEditTemplates =
        ref.watch(hasPermissionProvider(AppPermission.manageClassTemplates));

    return Scaffold(
      backgroundColor: GymGoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Plantillas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (canEditTemplates)
            IconButton(
              onPressed: _generateClasses,
              icon: const Icon(LucideIcons.sparkles, size: 20),
              tooltip: 'Generar clases',
            ),
          IconButton(
            onPressed: () => ref.invalidate(templatesProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 20),
          ),
        ],
      ),
      floatingActionButton: canEditTemplates
          ? FloatingActionButton(
              onPressed: _createTemplate,
              backgroundColor: GymGoColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GymGoTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Buscar plantilla...',
                hintStyle: GymGoTypography.bodyMedium.copyWith(
                  color: GymGoColors.textTertiary,
                ),
                prefixIcon: Icon(
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

          // Day filter chips
          _buildDayFilterChips(),

          // Templates list
          Expanded(
            child: templatesAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error.toString()),
              data: (templates) {
                if (templates.isEmpty) {
                  return _buildEmptyState(canEditTemplates);
                }

                // Group by day
                final grouped = _groupByDay(templates);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GymGoSpacing.screenHorizontal,
                    vertical: GymGoSpacing.sm,
                  ),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped.entries.elementAt(index);
                    final dayName = DayOfWeek.getName(entry.key);
                    final dayTemplates = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day header
                        Padding(
                          padding: const EdgeInsets.only(
                            top: GymGoSpacing.md,
                            bottom: GymGoSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Text(
                                dayName,
                                style: GymGoTypography.labelLarge.copyWith(
                                  color: GymGoColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${dayTemplates.length} ${dayTemplates.length == 1 ? 'plantilla' : 'plantillas'}',
                                style: GymGoTypography.labelSmall.copyWith(
                                  color: GymGoColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Templates for this day
                        ...dayTemplates.map((template) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: GymGoSpacing.sm),
                              child: _TemplateCard(
                                template: template,
                                canEdit: canEditTemplates,
                                onTap: canEditTemplates
                                    ? () => _editTemplate(template)
                                    : null,
                                onLongPress: canEditTemplates
                                    ? () => _showTemplateActions(template)
                                    : null,
                                onMorePressed: canEditTemplates
                                    ? () => _showTemplateActions(template)
                                    : null,
                              ),
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

  Widget _buildDayFilterChips() {
    final selectedDay = ref.watch(templateDayFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          _DayChip(
            label: 'Todos',
            isSelected: selectedDay == null,
            onTap: () =>
                ref.read(templateDayFilterProvider.notifier).state = null,
          ),
          for (var i = 0; i < 7; i++)
            _DayChip(
              label: DayOfWeek.getShortName(i),
              isSelected: selectedDay == i,
              onTap: () =>
                  ref.read(templateDayFilterProvider.notifier).state = i,
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

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: GymGoSpacing.md),
        child: GymGoCard(
          padding: const EdgeInsets.all(GymGoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GymGoShimmerBox(width: 80, height: 16),
              const SizedBox(height: GymGoSpacing.sm),
              GymGoShimmerBox(width: 150, height: 20),
              const SizedBox(height: GymGoSpacing.sm),
              GymGoShimmerBox(width: 120, height: 14),
            ],
          ),
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
              'Error al cargar plantillas',
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
              onPressed: () => ref.invalidate(templatesProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GymGoColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool canCreate) {
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
                LucideIcons.layoutTemplate,
                size: 36,
                color: GymGoColors.textTertiary,
              ),
            ),
            const SizedBox(height: GymGoSpacing.lg),
            Text(
              'Sin plantillas',
              style: GymGoTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No hay plantillas de clase configuradas',
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (canCreate) ...[
              const SizedBox(height: GymGoSpacing.lg),
              ElevatedButton.icon(
                onPressed: _createTemplate,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Crear plantilla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Day filter chip
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: GymGoSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? GymGoColors.primary : GymGoColors.surface,
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? GymGoColors.primary : GymGoColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: GymGoTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : GymGoColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Template card widget with actions
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.canEdit,
    this.onTap,
    this.onLongPress,
    this.onMorePressed,
  });

  final ClassTemplate template;
  final bool canEdit;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return GymGoCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Row(
        children: [
          // Time badge
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(
              horizontal: GymGoSpacing.sm,
              vertical: GymGoSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: GymGoColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: Column(
              children: [
                Text(
                  template.startTime,
                  style: GymGoTypography.labelMedium.copyWith(
                    color: GymGoColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  template.endTime,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.primary.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: GymGoSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: GymGoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (template.classType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GymGoColors.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template.classTypeLabel,
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.sm),
                    ],
                    Icon(
                      LucideIcons.users,
                      size: 12,
                      color: GymGoColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${template.maxCapacity}',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (template.instructorName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 12,
                        color: GymGoColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          template.instructorName!,
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (canEdit) ...[
            IconButton(
              onPressed: onMorePressed,
              icon: const Icon(LucideIcons.moreVertical),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              color: GymGoColors.textTertiary,
            ),
          ] else if (onTap != null) ...[
            const SizedBox(width: GymGoSpacing.sm),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: GymGoColors.textTertiary,
            ),
          ],
        ],
      ),
    );
  }
}
