import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../alternatives/presentation/widgets/alternatives_sheet.dart';
import '../../domain/exercise_media.dart';
import '../../domain/routine.dart';
import '../providers/routines_providers.dart';

/// Bottom sheet showing exercise details with media
class ExerciseDetailSheet extends ConsumerStatefulWidget {
  const ExerciseDetailSheet({
    super.key,
    required this.exercise,
    this.workoutId,
    this.onExerciseReplaced,
  });

  final ExerciseItem exercise;
  /// If provided, enables the "replace for today" feature
  final String? workoutId;
  /// Called when exercise is replaced, so parent can refresh
  final VoidCallback? onExerciseReplaced;

  @override
  ConsumerState<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<ExerciseDetailSheet> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  String? _videoError;
  late ExerciseMedia _media;

  @override
  void initState() {
    super.initState();
    // Resolve media URLs
    _media = ExerciseMediaResolver.resolveMedia(
      gifUrl: widget.exercise.gifUrl,
      videoUrl: widget.exercise.videoUrl,
      thumbnailUrl: widget.exercise.thumbnailUrl,
      preferVideo: true, // Prefer video in detail view
    );
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Don't initialize video player for YouTube videos
    if (_media.isYouTube) return;

    final videoUrl = _media.type == ExerciseMediaType.video ? _media.url : null;
    if (videoUrl == null || videoUrl.isEmpty) return;

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = 'No se pudo cargar el video';
        });
      }
    }
  }

  Future<void> _openYoutubeVideo() async {
    final videoUrl = widget.exercise.videoUrl;
    if (videoUrl == null) return;

    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_isVideoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isVideoPlaying = !_isVideoPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: GymGoSpacing.md),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GymGoColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Media section
                _buildMediaSection(),

                // Exercise info
                Padding(
                  padding: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.exercise.exerciseName,
                        style: GymGoTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      // Category and difficulty
                      if (widget.exercise.category != null ||
                          widget.exercise.difficulty != null) ...[
                        const SizedBox(height: GymGoSpacing.sm),
                        _buildBadges(),
                      ],

                      const SizedBox(height: GymGoSpacing.lg),

                      // Exercise parameters
                      _buildParametersCard(),

                      // Muscle groups
                      if (widget.exercise.muscleGroups != null &&
                          widget.exercise.muscleGroups!.isNotEmpty) ...[
                        const SizedBox(height: GymGoSpacing.lg),
                        _buildMuscleGroupsSection(),
                      ],

                      // Instructions
                      if (widget.exercise.instructions != null &&
                          widget.exercise.instructions!.isNotEmpty) ...[
                        const SizedBox(height: GymGoSpacing.lg),
                        _buildInstructionsSection(),
                      ],

                      // Notes
                      if (widget.exercise.notes != null &&
                          widget.exercise.notes!.isNotEmpty) ...[
                        const SizedBox(height: GymGoSpacing.lg),
                        _buildNotesSection(),
                      ],

                      // AI Alternatives button
                      const SizedBox(height: GymGoSpacing.lg),
                      _buildAlternativesButton(context),

                      const SizedBox(height: GymGoSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaSection() {
    // Check for YouTube video first
    if (_media.isYouTube) {
      return _buildYoutubePlayer();
    }

    // Direct video
    if (_media.type == ExerciseMediaType.video) {
      if (_isVideoInitialized) {
        return _buildVideoPlayer();
      }
      if (_videoError != null) {
        return _buildVideoError();
      }
      return _buildVideoLoading();
    }

    // GIF
    if (_media.type == ExerciseMediaType.gif && _media.url != null) {
      return _buildGifDisplay();
    }

    return _buildNoMediaPlaceholder();
  }

  Widget _buildYoutubePlayer() {
    final thumbnailUrl = _media.youtubeThumbnail ?? _media.thumbnailUrl;

    return GestureDetector(
      onTap: _openYoutubeVideo,
      child: Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: GymGoColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(color: GymGoColors.primary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: GymGoColors.surfaceLight,
                  ),
                ),
              // Play button overlay
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.play,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              // YouTube branding
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.youtube, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Ver en YouTube',
                        style: GymGoTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 250,
      margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            // Play/pause overlay
            GestureDetector(
              onTap: _toggleVideoPlayback,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _isVideoPlaying
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: _isVideoPlaying
                    ? null
                    : const Icon(
                        LucideIcons.play,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoading() {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: GymGoColors.primary),
      ),
    );
  }

  Widget _buildVideoError() {
    return Container(
      width: double.infinity,
      height: 150,
      margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.videoOff,
            size: 40,
            color: GymGoColors.textTertiary,
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            _videoError ?? 'Error al cargar video',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifDisplay() {
    final gifUrl = _media.url;
    if (gifUrl == null) return _buildNoMediaPlaceholder();

    return Container(
      width: double.infinity,
      height: 250,
      margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        child: CachedNetworkImage(
          imageUrl: gifUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: GymGoColors.primary),
          ),
          errorWidget: (_, __, ___) => _buildMediaUnavailable(),
        ),
      ),
    );
  }

  Widget _buildMediaUnavailable() {
    return Container(
      width: double.infinity,
      height: 150,
      margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.imageOff,
            size: 40,
            color: GymGoColors.textTertiary,
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            'Media no disponible',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMediaPlaceholder() {
    return Container(
      width: double.infinity,
      height: 150,
      margin: const EdgeInsets.all(GymGoSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.image,
            size: 40,
            color: GymGoColors.textTertiary,
          ),
          const SizedBox(height: GymGoSpacing.sm),
          Text(
            'Sin contenido visual',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: GymGoSpacing.sm,
      children: [
        if (widget.exercise.category != null)
          _buildBadge(
            widget.exercise.category!,
            GymGoColors.primary,
          ),
        if (widget.exercise.difficulty != null)
          _buildBadge(
            widget.exercise.difficulty!,
            _getDifficultyColor(widget.exercise.difficulty!),
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
      ),
      child: Text(
        text,
        style: GymGoTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (widget.exercise.sets != null)
            _buildParameter(
              icon: LucideIcons.layers,
              label: 'Series',
              value: widget.exercise.sets.toString(),
            ),
          if (widget.exercise.reps != null)
            _buildParameter(
              icon: LucideIcons.repeat,
              label: 'Reps',
              value: widget.exercise.reps!,
            ),
          if (widget.exercise.weight != null &&
              widget.exercise.weight!.isNotEmpty)
            _buildParameter(
              icon: LucideIcons.scale,
              label: 'Peso',
              value: widget.exercise.weight!,
            ),
          if (widget.exercise.restSeconds != null &&
              widget.exercise.restSeconds! > 0)
            _buildParameter(
              icon: LucideIcons.clock,
              label: 'Descanso',
              value: widget.exercise.restDisplay,
            ),
        ],
      ),
    );
  }

  Widget _buildParameter({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: GymGoColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: GymGoTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Músculos trabajados'),
        const SizedBox(height: GymGoSpacing.sm),
        Wrap(
          spacing: GymGoSpacing.sm,
          runSpacing: GymGoSpacing.sm,
          children: widget.exercise.muscleGroups!
              .map((muscle) => _buildMuscleChip(muscle))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMuscleChip(String muscle) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.md,
        vertical: GymGoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
        border: Border.all(
          color: GymGoColors.info.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        muscle,
        style: GymGoTypography.labelMedium.copyWith(
          color: GymGoColors.info,
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Instrucciones'),
        const SizedBox(height: GymGoSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GymGoSpacing.md),
          decoration: BoxDecoration(
            color: GymGoColors.surfaceLight,
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          ),
          child: Text(
            widget.exercise.instructions!,
            style: GymGoTypography.bodyMedium.copyWith(
              color: GymGoColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notas del entrenador'),
        const SizedBox(height: GymGoSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(GymGoSpacing.md),
          decoration: BoxDecoration(
            color: GymGoColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            border: Border.all(
              color: GymGoColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.stickyNote,
                size: 18,
                color: GymGoColors.warning,
              ),
              const SizedBox(width: GymGoSpacing.sm),
              Expanded(
                child: Text(
                  widget.exercise.notes!,
                  style: GymGoTypography.bodyMedium.copyWith(
                    color: GymGoColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GymGoTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAlternativesButton(BuildContext context) {
    final canReplace = widget.workoutId != null;

    return OutlinedButton.icon(
      onPressed: () {
        if (canReplace) {
          // IMPORTANT: Capture everything BEFORE closing this sheet
          // because ref and widget will be invalid after pop()
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final repository = ref.read(routinesRepositoryProvider);
          final workoutId = widget.workoutId!;
          final exerciseId = widget.exercise.exerciseId;
          final exerciseName = widget.exercise.exerciseName;
          final exerciseOrder = widget.exercise.order;
          final onExerciseReplaced = widget.onExerciseReplaced;

          navigator.pop();

          // Use a post-frame callback to ensure the previous sheet is fully closed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Get a fresh context from the navigator
            if (navigator.context.mounted) {
              AlternativesSheet.showWithSelection(
                context: navigator.context,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                onSelect: (alternative) async {
                  // Use the pre-captured repository
                  await repository.substituteExercise(
                    workoutId: workoutId,
                    originalExerciseId: exerciseId,
                    exerciseOrder: exerciseOrder,
                    replacementExerciseId: alternative.exercise.id,
                    reason: alternative.reason,
                  );

                  // Notify parent to refresh
                  onExerciseReplaced?.call();

                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ejercicio reemplazado por "${alternative.exercise.displayName}" para hoy',
                      ),
                      backgroundColor: GymGoColors.success,
                    ),
                  );
                },
              );
            }
          });
        } else {
          // View only mode - close this sheet first
          final navigator = Navigator.of(context);
          navigator.pop();

          // Use a post-frame callback to ensure the previous sheet is fully closed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (navigator.context.mounted) {
              AlternativesSheet.show(
                context: navigator.context,
                exerciseId: widget.exercise.exerciseId,
                exerciseName: widget.exercise.exerciseName,
              );
            }
          });
        }
      },
      icon: Icon(canReplace ? LucideIcons.repeat : LucideIcons.sparkles, size: 18),
      label: Text(canReplace ? 'Cambiar ejercicio por hoy' : 'Ver alternativas IA'),
      style: OutlinedButton.styleFrom(
        foregroundColor: GymGoColors.primary,
        side: const BorderSide(color: GymGoColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
      case 'beginner':
        return GymGoColors.success;
      case 'intermedio':
      case 'intermediate':
        return GymGoColors.warning;
      case 'avanzado':
      case 'advanced':
        return GymGoColors.error;
      default:
        return GymGoColors.info;
    }
  }
}
