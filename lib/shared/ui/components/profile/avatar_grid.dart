import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/config/avatars.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';

/// Grid of predefined avatars for selection
class AvatarGrid extends StatelessWidget {
  const AvatarGrid({
    super.key,
    required this.onSelect,
    this.selectedAvatarPath,
    this.itemSize = 64,
    this.spacing = 12,
    this.crossAxisCount = 4,
    this.showCategories = true,
  });

  /// Callback when an avatar is selected
  final ValueChanged<String> onSelect;

  /// Currently selected avatar path
  final String? selectedAvatarPath;

  /// Size of each avatar item
  final double itemSize;

  /// Spacing between items
  final double spacing;

  /// Number of columns in grid
  final int crossAxisCount;

  /// Whether to show category headers
  final bool showCategories;

  @override
  Widget build(BuildContext context) {
    if (showCategories) {
      return _buildCategorizedGrid();
    }
    return _buildSimpleGrid();
  }

  Widget _buildSimpleGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: AvatarConfig.avatars.length,
      itemBuilder: (context, index) {
        final avatarPath = AvatarConfig.avatars[index];
        return _AvatarItem(
          avatarPath: avatarPath,
          isSelected: selectedAvatarPath == avatarPath,
          size: itemSize,
          onTap: () => onSelect(avatarPath),
        );
      },
    );
  }

  Widget _buildCategorizedGrid() {
    final categories = AvatarOption.byCategory;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: GymGoSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final entry = categories.entries.elementAt(index);
        final categoryName = entry.key;
        final avatars = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: GymGoSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(
                bottom: GymGoSpacing.sm,
                left: GymGoSpacing.xs,
              ),
              child: Text(
                categoryName,
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
            ),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: avatars.map((avatar) {
                return _AvatarItem(
                  avatarPath: avatar.path,
                  isSelected: selectedAvatarPath == avatar.path,
                  size: itemSize,
                  onTap: () => onSelect(avatar.path),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// Individual avatar item in the grid
class _AvatarItem extends StatelessWidget {
  const _AvatarItem({
    required this.avatarPath,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  final String avatarPath;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: GymGoColors.surface,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? GymGoColors.primary : GymGoColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GymGoColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd - 2),
          child: Stack(
            children: [
              // Avatar content
              Padding(
                padding: const EdgeInsets.all(8),
                child: _buildAvatarContent(),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: GymGoColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: GymGoColors.background,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    final fullPath = AvatarConfig.getAvatarUrl(avatarPath);

    // Check if it's an SVG
    if (avatarPath.endsWith('.svg')) {
      // Check if it's a local asset or network URL
      if (fullPath.startsWith('assets/')) {
        return SvgPicture.asset(
          fullPath,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildPlaceholder(),
        );
      } else {
        return SvgPicture.network(
          fullPath,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildPlaceholder(),
        );
      }
    }

    // Regular image
    if (fullPath.startsWith('assets/')) {
      return Image.asset(
        fullPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Image.network(
      fullPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: GymGoColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.person_outline,
          color: GymGoColors.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}

/// Compact avatar selector for inline use
class AvatarSelector extends StatelessWidget {
  const AvatarSelector({
    super.key,
    required this.onSelect,
    this.selectedAvatarPath,
    this.itemSize = 48,
    this.maxVisible = 6,
  });

  final ValueChanged<String> onSelect;
  final String? selectedAvatarPath;
  final double itemSize;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final avatars = AvatarConfig.avatars.take(maxVisible).toList();

    return SizedBox(
      height: itemSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: avatars.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final avatarPath = avatars[index];
          return _AvatarItem(
            avatarPath: avatarPath,
            isSelected: selectedAvatarPath == avatarPath,
            size: itemSize,
            onTap: () => onSelect(avatarPath),
          );
        },
      ),
    );
  }
}
