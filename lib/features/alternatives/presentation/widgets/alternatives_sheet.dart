import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/exercise_alternative.dart';
import '../providers/alternatives_providers.dart';
import 'alternative_card.dart';

/// Callback when user selects an alternative to replace the exercise
typedef OnAlternativeSelected = Future<void> Function(ExerciseAlternative alternative);

/// Bottom sheet displaying AI-powered exercise alternatives
class AlternativesSheet extends ConsumerStatefulWidget {
  const AlternativesSheet({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    this.onSelect,
  });

  final String exerciseId;
  final String exerciseName;
  /// If provided, tapping an alternative will call this and close the sheet
  final OnAlternativeSelected? onSelect;

  /// Show the alternatives sheet (view only mode)
  static Future<void> show({
    required BuildContext context,
    required String exerciseId,
    required String exerciseName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlternativesSheet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
      ),
    );
  }

  /// Show the alternatives sheet with selection capability
  static Future<void> showWithSelection({
    required BuildContext context,
    required String exerciseId,
    required String exerciseName,
    required OnAlternativeSelected onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlternativesSheet(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        onSelect: onSelect,
      ),
    );
  }

  @override
  ConsumerState<AlternativesSheet> createState() => _AlternativesSheetState();
}

class _AlternativesSheetState extends ConsumerState<AlternativesSheet> {
  bool _isSelecting = false;

  Future<void> _handleSelect(ExerciseAlternative alternative) async {
    if (widget.onSelect == null || _isSelecting) return;

    setState(() => _isSelecting = true);

    try {
      await widget.onSelect!(alternative);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSelecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reemplazar: $e'),
            backgroundColor: GymGoColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alternativesAsync = ref.watch(simpleAlternativesProvider(widget.exerciseId));

    return Container(
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header (fixed)
              _buildHeader(),

              // Content (scrollable)
              Expanded(
                child: alternativesAsync.when(
                  data: (response) => _buildContent(
                    scrollController,
                    response.alternatives,
                    response.remainingRequests,
                  ),
                  loading: () => _buildLoading(),
                  error: (error, _) => _buildError(error),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        GymGoSpacing.screenHorizontal,
        GymGoSpacing.md,
        GymGoSpacing.md,
        GymGoSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: GymGoColors.cardBorder),
        ),
      ),
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

          // Title row
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GymGoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: GymGoColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: GymGoSpacing.sm),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.onSelect != null ? 'Selecciona alternativa' : 'Alternativas IA',
                      style: GymGoTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.exerciseName,
                      style: GymGoTypography.bodySmall.copyWith(
                        color: GymGoColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Close button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  LucideIcons.x,
                  color: GymGoColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: GymGoColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Buscando alternativas...',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    String message = 'Error al cargar alternativas';
    IconData icon = LucideIcons.alertTriangle;

    if (error is RateLimitException) {
      message = error.message;
      icon = LucideIcons.clock;
    } else if (error is AiDisabledException) {
      message = error.message;
      icon = LucideIcons.ban;
    } else if (error is UnauthorizedException) {
      message = error.message;
      icon = LucideIcons.logOut;
    } else if (error is ApiException) {
      message = error.message;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: GymGoColors.error,
            ),
            const SizedBox(height: GymGoSpacing.md),
            Text(
              message,
              style: GymGoTypography.bodyMedium.copyWith(
                color: GymGoColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GymGoSpacing.lg),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(simpleAlternativesProvider(widget.exerciseId));
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GymGoColors.primary,
                side: const BorderSide(color: GymGoColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ScrollController scrollController,
    List<ExerciseAlternative> alternatives,
    int remainingRequests,
  ) {
    if (alternatives.isEmpty) {
      return _buildEmpty();
    }

    final canSelect = widget.onSelect != null && !_isSelecting;

    return Stack(
      children: [
        ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
          children: [
            // Hint text when in selection mode
            if (widget.onSelect != null) ...[
              Container(
                padding: const EdgeInsets.all(GymGoSpacing.sm),
                decoration: BoxDecoration(
                  color: GymGoColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: GymGoColors.primary),
                    const SizedBox(width: GymGoSpacing.xs),
                    Expanded(
                      child: Text(
                        'Toca una alternativa para reemplazar el ejercicio solo por hoy',
                        style: GymGoTypography.bodySmall.copyWith(
                          color: GymGoColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GymGoSpacing.md),
            ],

            // Alternatives list
            ...alternatives.map((alt) => Padding(
                  padding: const EdgeInsets.only(bottom: GymGoSpacing.sm),
                  child: AlternativeCard(
                    alternative: alt,
                    onTap: canSelect ? () => _handleSelect(alt) : null,
                  ),
                )),

            const SizedBox(height: GymGoSpacing.md),

            // Footer with remaining requests
            _buildFooter(remainingRequests),

            const SizedBox(height: GymGoSpacing.xxl),
          ],
        ),

        // Loading overlay when selecting
        if (_isSelecting)
          Container(
            color: GymGoColors.background.withValues(alpha: 0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: GymGoColors.primary),
                  SizedBox(height: GymGoSpacing.md),
                  Text('Reemplazando ejercicio...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
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
            'Sin alternativas disponibles',
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            'No encontramos ejercicios similares\ncon el equipo disponible',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int remainingRequests) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.info,
            size: 16,
            color: GymGoColors.textTertiary,
          ),
          const SizedBox(width: GymGoSpacing.xs),
          Text(
            'Te quedan $remainingRequests solicitudes este mes',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
