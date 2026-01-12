import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../models/member.dart';
import '../../../models/profile_photo_selection.dart';
import '../../../providers/profile_image_picker_provider.dart';
import 'avatar_grid.dart';
import 'image_preview.dart';
import 'photo_fallback.dart';

/// Bottom sheet for selecting profile photo
/// Supports two tabs: Upload and Avatars
class ProfileImagePickerSheet extends ConsumerStatefulWidget {
  const ProfileImagePickerSheet({
    super.key,
    required this.member,
    required this.onSave,
    this.onSavedOptimistic,
  });

  /// Current member data
  final Member member;

  /// Callback when save is pressed - should handle API call
  final Future<void> Function(ProfilePhotoSelection selection) onSave;

  /// Optional callback for optimistic UI update
  final void Function(ProfilePhotoSelection selection)? onSavedOptimistic;

  /// Show the sheet
  static Future<ProfilePhotoSelection?> show({
    required BuildContext context,
    required Member member,
    required Future<void> Function(ProfilePhotoSelection selection) onSave,
    void Function(ProfilePhotoSelection selection)? onSavedOptimistic,
  }) {
    return showModalBottomSheet<ProfilePhotoSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileImagePickerSheet(
        member: member,
        onSave: onSave,
        onSavedOptimistic: onSavedOptimistic,
      ),
    );
  }

  @override
  ConsumerState<ProfileImagePickerSheet> createState() =>
      _ProfileImagePickerSheetState();
}

class _ProfileImagePickerSheetState
    extends ConsumerState<ProfileImagePickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileImagePickerProvider(widget.member));
    final controller =
        ref.read(profileImagePickerProvider(widget.member).notifier);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final sheetHeight = screenHeight * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: sheetHeight,
        maxWidth: screenWidth,
        minWidth: screenWidth,
      ),
      child: Material(
        color: GymGoColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GymGoSpacing.radiusXl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            _buildHandle(),

            // Header
            _buildHeader(state, controller),

            // Error message
            if (state.error != null) _buildError(state.error!),

            // Tabs
            _buildTabs(),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Upload tab
                  _UploadTab(
                    state: state,
                    controller: controller,
                    member: widget.member,
                  ),
                  // Avatars tab
                  _AvatarsTab(
                    state: state,
                    controller: controller,
                  ),
                ],
              ),
            ),

            // Footer actions
            _buildFooter(state, controller, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GymGoSpacing.sm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: GymGoColors.cardBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ProfileImagePickerState state,
    ProfileImagePickerController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.lg,
        vertical: GymGoSpacing.sm,
      ),
      child: Row(
        children: [
          // Current preview
          _buildCurrentPreview(state),
          const SizedBox(width: GymGoSpacing.md),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto de perfil',
                  style: GymGoTypography.headlineSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  state.hasChanges ? 'Cambios sin guardar' : 'Selecciona una opción',
                  style: GymGoTypography.bodySmall.copyWith(
                    color: state.hasChanges
                        ? GymGoColors.warning
                        : GymGoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x),
            color: GymGoColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPreview(ProfileImagePickerState state) {
    return SizedBox(
      width: 56,
      height: 56,
      child: state.selection.when(
        none: () => PhotoFallback(
          initials: widget.member.initials,
          size: 56,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
        avatar: (path) => _AvatarPreview(avatarPath: path, size: 56),
        upload: (file, bytes) => ImagePreview(
          file: file,
          bytes: bytes,
          size: 56,
          showRemoveButton: false,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.lg,
        vertical: GymGoSpacing.sm,
      ),
      padding: const EdgeInsets.all(GymGoSpacing.sm),
      decoration: BoxDecoration(
        color: GymGoColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: GymGoColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            color: GymGoColors.error,
            size: 20,
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.lg,
        vertical: GymGoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: GymGoColors.primary,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd - 2),
        ),
        labelColor: GymGoColors.background,
        unselectedLabelColor: GymGoColors.textSecondary,
        labelStyle: GymGoTypography.labelMedium,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Subir foto'),
          Tab(text: 'Avatares'),
        ],
      ),
    );
  }

  Widget _buildFooter(
    ProfileImagePickerState state,
    ProfileImagePickerController controller,
    double width,
  ) {
    final showRemoveButton = widget.member.hasProfileImage || !state.selection.isNone;

    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.only(
          left: GymGoSpacing.lg,
          right: GymGoSpacing.lg,
          top: GymGoSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + GymGoSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: GymGoColors.surface,
          border: Border(
            top: BorderSide(
              color: GymGoColors.cardBorder,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Remove button (left side)
            if (showRemoveButton)
              IntrinsicWidth(
                child: TextButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          controller.removePhoto();
                        },
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  label: const Text('Quitar'),
                  style: TextButton.styleFrom(
                    foregroundColor: GymGoColors.error,
                  ),
                ),
              ),
            // Flexible spacer
            const Expanded(child: SizedBox.shrink()),
            // Cancel button
            IntrinsicWidth(
              child: TextButton(
                onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: GymGoColors.textSecondary,
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: GymGoSpacing.sm),
            // Save button
            IntrinsicWidth(
              child: ElevatedButton(
                onPressed: state.canSave ? () => _handleSave(state, controller) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GymGoColors.primary,
                  foregroundColor: GymGoColors.background,
                  disabledBackgroundColor: GymGoColors.surfaceLight,
                  disabledForegroundColor: GymGoColors.textTertiary,
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GymGoColors.background,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(
    ProfileImagePickerState state,
    ProfileImagePickerController controller,
  ) async {
    HapticFeedback.mediumImpact();
    controller.setLoading(true);

    // Optimistic update
    widget.onSavedOptimistic?.call(state.selection);

    try {
      await widget.onSave(state.selection);
      controller.confirmSave();
      if (mounted) {
        Navigator.of(context).pop(state.selection);
      }
    } catch (e) {
      controller.setError(e.toString());
    }
  }
}

/// Upload tab content
class _UploadTab extends StatelessWidget {
  const _UploadTab({
    required this.state,
    required this.controller,
    required this.member,
  });

  final ProfileImagePickerState state;
  final ProfileImagePickerController controller;
  final Member member;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(GymGoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current preview or upload area
          Center(
            child: state.selection.maybeWhen(
              upload: (file, bytes) => ImagePreviewLarge(
                file: file,
                bytes: bytes,
                onRemove: controller.removePhoto,
              ),
              orElse: () => _buildUploadArea(),
            ),
          ),
          const SizedBox(height: GymGoSpacing.xl),
          // Upload buttons
          Row(
            children: [
              Expanded(
                child: _UploadButton(
                  icon: LucideIcons.image,
                  label: 'Galería',
                  onTap: state.isLoading ? null : controller.pickFromGallery,
                ),
              ),
              const SizedBox(width: GymGoSpacing.md),
              Expanded(
                child: _UploadButton(
                  icon: LucideIcons.camera,
                  label: 'Cámara',
                  onTap: state.isLoading ? null : controller.pickFromCamera,
                ),
              ),
            ],
          ),
          const SizedBox(height: GymGoSpacing.lg),
          // Info text
          Text(
            'Formatos: JPG, PNG, WebP\nTamaño máximo: 5MB',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: GymGoColors.surfaceLight,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        border: Border.all(
          color: GymGoColors.cardBorder,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: GymGoColors.surface,
              borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.upload,
                color: GymGoColors.textTertiary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: GymGoSpacing.md),
          Text(
            'Sube una foto',
            style: GymGoTypography.titleMedium.copyWith(
              color: GymGoColors.textSecondary,
            ),
          ),
          const SizedBox(height: GymGoSpacing.xs),
          Text(
            'Selecciona desde galería o toma una foto',
            style: GymGoTypography.bodySmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GymGoColors.surfaceLight,
      borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.lg,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: onTap == null
                    ? GymGoColors.textTertiary
                    : GymGoColors.primary,
                size: 28,
              ),
              const SizedBox(height: GymGoSpacing.sm),
              Text(
                label,
                style: GymGoTypography.labelMedium.copyWith(
                  color: onTap == null
                      ? GymGoColors.textTertiary
                      : GymGoColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatars tab content
class _AvatarsTab extends StatelessWidget {
  const _AvatarsTab({
    required this.state,
    required this.controller,
  });

  final ProfileImagePickerState state;
  final ProfileImagePickerController controller;

  @override
  Widget build(BuildContext context) {
    final selectedAvatar = state.selection.maybeWhen(
      avatar: (path) => path,
      orElse: () => null,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: GymGoSpacing.lg),
        child: AvatarGrid(
          selectedAvatarPath: selectedAvatar,
          onSelect: (path) {
            HapticFeedback.selectionClick();
            controller.selectAvatar(path);
          },
          showCategories: true,
        ),
      ),
    );
  }
}

/// Small avatar preview widget
class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.avatarPath,
    required this.size,
  });

  final String avatarPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(
          color: GymGoColors.primary.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd - 2),
        child: Image.asset(
          'assets/$avatarPath',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.person_outline,
              color: GymGoColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
