import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Preview widget for selected image before upload
class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
    this.file,
    this.bytes,
    this.size = 120,
    this.borderRadius,
    this.onRemove,
    this.showRemoveButton = true,
  });

  /// The file to preview
  final File? file;

  /// Alternatively, bytes data for preview
  final Uint8List? bytes;

  /// Size of the preview container
  final double size;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Callback when remove button is pressed
  final VoidCallback? onRemove;

  /// Whether to show remove button
  final bool showRemoveButton;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(GymGoSpacing.radiusLg);

    if (file == null && bytes == null) {
      return _buildEmptyState(effectiveBorderRadius);
    }

    return Stack(
      children: [
        // Image preview
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: GymGoColors.primary.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              GymGoSpacing.radiusLg - 2,
            ),
            child: _buildImage(),
          ),
        ),
        // Remove button
        if (showRemoveButton && onRemove != null)
          Positioned(
            top: -8,
            right: -8,
            child: _RemoveButton(onTap: onRemove!),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    if (file != null) {
      return Image.file(
        file!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(),
      );
    }

    return _buildErrorPlaceholder();
  }

  Widget _buildEmptyState(BorderRadius borderRadius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color: GymGoColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            color: GymGoColors.textTertiary,
            size: 32,
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            'Sin imagen',
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: GymGoColors.surface,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: GymGoColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: GymGoColors.error,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

/// Large image preview with file info
class ImagePreviewLarge extends StatelessWidget {
  const ImagePreviewLarge({
    super.key,
    required this.file,
    this.bytes,
    this.onRemove,
    this.maxHeight = 200,
  });

  final File file;
  final Uint8List? bytes;
  final VoidCallback? onRemove;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        border: Border.all(
          color: GymGoColors.cardBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg - 1),
        child: Stack(
          children: [
            // Image
            if (bytes != null)
              Image.memory(
                bytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            // Overlay with info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(GymGoSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getFileName(),
                        style: GymGoTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onRemove != null)
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 20,
                          ),
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

  String _getFileName() {
    final path = file.path;
    return path.split('/').last;
  }

  Widget _buildPlaceholder() {
    return Container(
      height: maxHeight,
      color: GymGoColors.surface,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: GymGoColors.textTertiary,
          size: 48,
        ),
      ),
    );
  }
}
