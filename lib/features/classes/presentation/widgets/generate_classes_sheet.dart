import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/class_generation.dart';
import '../../domain/class_template.dart';
import '../providers/class_generation_providers.dart';

/// Bottom sheet for generating classes from templates
class GenerateClassesSheet extends ConsumerStatefulWidget {
  const GenerateClassesSheet({super.key});

  /// Show the generate classes sheet
  static Future<GenerationResult?> show(BuildContext context) {
    return showModalBottomSheet<GenerationResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Use root navigator to avoid go_router conflicts
      backgroundColor: GymGoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusLg),
        ),
      ),
      builder: (context) => const GenerateClassesSheet(),
    );
  }

  @override
  ConsumerState<GenerateClassesSheet> createState() =>
      _GenerateClassesSheetState();
}

class _GenerateClassesSheetState extends ConsumerState<GenerateClassesSheet> {
  bool _isGenerating = false;
  GenerationResult? _result;

  @override
  void initState() {
    super.initState();
    // Load preview for default period
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final period = ref.read(selectedGenerationPeriodProvider);
      ref.read(previewGenerationProvider.notifier).loadPreview(period);
    });
  }

  void _onPeriodChanged(GenerationPeriod period) {
    ref.read(selectedGenerationPeriodProvider.notifier).state = period;
    ref.read(previewGenerationProvider.notifier).loadPreview(period);
  }

  Future<void> _generate() async {
    final period = ref.read(selectedGenerationPeriodProvider);
    final preview = ref.read(previewGenerationProvider).valueOrNull;

    // Confirm for 30 days
    if (period == GenerationPeriod.month) {
      final confirmed = await _showConfirmationDialog(
        title: 'Confirmar generación',
        message:
            'Esto creará ${preview?.totalToGenerate ?? 0} clases para los próximos 30 días. ¿Deseas continuar?',
      );
      if (!confirmed) return;
    }

    setState(() {
      _isGenerating = true;
    });

    final result =
        await ref.read(generateClassesProvider.notifier).generate(period);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _result = result;
      });

      if (result != null && result.success && mounted) {
        Navigator.of(context, rootNavigator: true).pop(result);
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true, // Use root navigator to avoid go_router conflicts
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
                color: GymGoColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: GymGoColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),
            Expanded(
              child: Text(title, style: GymGoTypography.headlineSmall),
            ),
          ],
        ),
        content: Text(
          message,
          style: GymGoTypography.bodyMedium.copyWith(
            color: GymGoColors.textSecondary,
          ),
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
              backgroundColor: GymGoColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedGenerationPeriodProvider);
    final previewAsync = ref.watch(previewGenerationProvider);
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: GymGoColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                  child: const Icon(
                    LucideIcons.calendarPlus,
                    size: 22,
                    color: GymGoColors.primary,
                  ),
                ),
                const SizedBox(width: GymGoSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generar clases',
                        style: GymGoTypography.headlineSmall,
                      ),
                      Text(
                        'Crea clases automáticamente desde plantillas activas',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  icon: const Icon(LucideIcons.x),
                  iconSize: 20,
                  color: GymGoColors.textSecondary,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Text(
                    'Período',
                    style: GymGoTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.sm),
                  _buildPeriodSelector(selectedPeriod),

                  const SizedBox(height: GymGoSpacing.lg),

                  // Preview section
                  Text(
                    'Vista previa',
                    style: GymGoTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GymGoSpacing.sm),

                  previewAsync.when(
                    loading: () => _buildPreviewLoading(),
                    error: (error, _) => _buildPreviewError(error.toString()),
                    data: (preview) => _buildPreviewContent(preview),
                  ),

                  // Error result
                  if (_result != null && !_result!.success) ...[
                    const SizedBox(height: GymGoSpacing.md),
                    _buildErrorResult(_result!),
                  ],
                ],
              ),
            ),
          ),

          // Bottom actions
          _buildBottomActions(selectedPeriod, previewAsync),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(GenerationPeriod selected) {
    return Row(
      children: GenerationPeriod.values.map((period) {
        final isSelected = period == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: period != GenerationPeriod.month ? GymGoSpacing.sm : 0,
            ),
            child: InkWell(
              onTap: _isGenerating ? null : () => _onPeriodChanged(period),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: GymGoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? GymGoColors.primary : GymGoColors.surface,
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? GymGoColors.primary
                        : GymGoColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${period.days}',
                      style: GymGoTypography.headlineSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : GymGoColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'días',
                      style: GymGoTypography.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white70
                            : GymGoColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewLoading() {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.lg),
      child: Column(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GymGoColors.primary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            'Calculando clases...',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewError(String error) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      backgroundColor: GymGoColors.error.withValues(alpha: 0.1),
      borderColor: GymGoColors.error.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 20,
            color: GymGoColors.error,
          ),
          const SizedBox(width: GymGoSpacing.sm),
          Expanded(
            child: Text(
              error,
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(GenerationPreview preview) {
    if (preview.templatePreviews.isEmpty) {
      return GymGoCard(
        padding: const EdgeInsets.all(GymGoSpacing.lg),
        child: Column(
          children: [
            Icon(
              LucideIcons.layoutTemplate,
              size: 32,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(height: GymGoSpacing.sm),
            Text(
              'No hay plantillas activas',
              style: GymGoTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GymGoSpacing.xs),
            Text(
              'Activa algunas plantillas para poder generar clases',
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        GymGoCard(
          padding: const EdgeInsets.all(GymGoSpacing.md),
          child: Row(
            children: [
              _buildSummaryItem(
                icon: LucideIcons.layoutTemplate,
                label: 'Plantillas',
                value: '${preview.templateCount}',
                color: GymGoColors.info,
              ),
              const SizedBox(width: GymGoSpacing.md),
              _buildSummaryItem(
                icon: LucideIcons.calendarPlus,
                label: 'Nuevas',
                value: '${preview.totalToGenerate}',
                color: GymGoColors.success,
              ),
              const SizedBox(width: GymGoSpacing.md),
              _buildSummaryItem(
                icon: LucideIcons.calendarCheck,
                label: 'Existentes',
                value: '${preview.totalSkipped}',
                color: GymGoColors.textTertiary,
              ),
            ],
          ),
        ),

        const SizedBox(height: GymGoSpacing.md),

        // Templates list
        ...preview.templatePreviews.map((tp) => Padding(
              padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
              child: _buildTemplatePreviewCard(tp),
            )),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            value,
            style: GymGoTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreviewCard(TemplateGenerationPreview preview) {
    final template = preview.template;

    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.sm),
      child: Row(
        children: [
          // Day badge
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.xs),
            decoration: BoxDecoration(
              color: GymGoColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            ),
            child: Column(
              children: [
                Text(
                  DayOfWeek.getShortName(template.dayOfWeek),
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  template.startTime,
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.primary.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: GymGoSpacing.sm),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: GymGoTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (preview.newClassesCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: GymGoColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${preview.newClassesCount}',
                          style: GymGoTypography.labelSmall.copyWith(
                            color: GymGoColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: GymGoSpacing.xs),
                    ],
                    if (preview.skippedCount > 0)
                      Text(
                        '${preview.skippedCount} existentes',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: GymGoColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Dates chips
          if (preview.toGenerate.isNotEmpty)
            Wrap(
              spacing: 4,
              children: preview.toGenerate.take(3).map((date) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: GymGoColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: GymGoColors.cardBorder),
                  ),
                  child: Text(
                    '${date.day}/${date.month}',
                    style: GymGoTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: GymGoColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorResult(GenerationResult result) {
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      backgroundColor: GymGoColors.error.withValues(alpha: 0.1),
      borderColor: GymGoColors.error.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, size: 20, color: GymGoColors.error),
              const SizedBox(width: GymGoSpacing.sm),
              Expanded(
                child: Text(
                  result.message,
                  style: GymGoTypography.bodySmall.copyWith(
                    color: GymGoColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: GymGoSpacing.sm),
            ...result.errors.take(3).map((error) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• $error',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.error.withValues(alpha: 0.8),
                    ),
                  ),
                )),
            if (result.errors.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... y ${result.errors.length - 3} más',
                  style: GymGoTypography.labelSmall.copyWith(
                    color: GymGoColors.error.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    GenerationPeriod period,
    AsyncValue<GenerationPreview> previewAsync,
  ) {
    final preview = previewAsync.valueOrNull;
    final canGenerate = preview != null &&
        preview.hasClassesToGenerate &&
        !_isGenerating;

    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.background,
        border: Border(
          top: BorderSide(color: GymGoColors.cardBorder),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isGenerating ? null : () => Navigator.of(context, rootNavigator: true).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
                  side: BorderSide(color: GymGoColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: GymGoTypography.labelMedium.copyWith(
                    color: GymGoColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canGenerate ? _generate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                  ),
                  disabledBackgroundColor:
                      GymGoColors.primary.withValues(alpha: 0.3),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.sparkles, size: 18),
                          const SizedBox(width: GymGoSpacing.xs),
                          Text(
                            preview?.totalToGenerate != null &&
                                    preview!.totalToGenerate > 0
                                ? 'Generar ${preview.totalToGenerate} clases'
                                : 'Generar clases',
                            style: GymGoTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
