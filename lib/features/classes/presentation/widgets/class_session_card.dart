import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../domain/gym_class.dart';

/// Class session card matching the reference design
/// Shows class name, time, instructor, enrolled avatars grid with capacity slots
class ClassSessionCard extends StatelessWidget {
  const ClassSessionCard({
    super.key,
    required this.gymClass,
    required this.onTap,
    required this.onActionPressed,
    this.isLoading = false,
  });

  final GymClass gymClass;
  final VoidCallback onTap;
  final VoidCallback onActionPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: GymGoColors.cardBackground,
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          border: Border.all(color: GymGoColors.cardBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: gymClass.isUserBooked ? GymGoColors.primary : GymGoColors.textTertiary,
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(GymGoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Class name + Time
                  _buildHeader(),
                  const SizedBox(height: GymGoSpacing.sm),

                  // Instructor info
                  _buildInstructorInfo(),
                  const SizedBox(height: GymGoSpacing.md),

                  // Enrolled avatars grid with capacity slots
                  _buildAvatarsSection(),
                  const SizedBox(height: GymGoSpacing.md),

                  // Action button aligned right
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class name
        Expanded(
          child: Text(
            gymClass.name.toUpperCase(),
            style: GymGoTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: GymGoSpacing.md),
        // Time
        Text(
          gymClass.startTime,
          style: GymGoTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w400,
            color: GymGoColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorInfo() {
    return Row(
      children: [
        // Instructor avatar/logo
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
            color: GymGoColors.surface,
            border: Border.all(
              color: GymGoColors.cardBorder,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm - 1),
            child: _buildInstructorPlaceholder(),
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          gymClass.instructorName,
          style: GymGoTypography.labelMedium.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorPlaceholder() {
    return Container(
      color: GymGoColors.surfaceLight,
      child: const Center(
        child: Icon(
          LucideIcons.dumbbell,
          size: 16,
          color: GymGoColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildAvatarsSection() {
    // Display capacity info without enrolled members list
    return Row(
      children: [
        Icon(
          LucideIcons.users,
          size: 16,
          color: GymGoColors.textSecondary,
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          '${gymClass.currentParticipants}/${gymClass.maxCapacity}',
          style: GymGoTypography.labelMedium.copyWith(
            color: GymGoColors.textSecondary,
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        Text(
          'inscritos',
          style: GymGoTypography.labelSmall.copyWith(
            color: GymGoColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(),
      ],
    );
  }

  Widget _buildActionButton() {
    // Class is finished
    if (gymClass.status == ClassStatus.finished) {
      return _ActionButton(
        label: 'Finalizada',
        icon: null,
        onPressed: null,
        isOutlined: true,
        isDisabled: true,
      );
    }

    // User is already booked - show "Cambiar" button
    if (gymClass.isUserBooked) {
      return _ActionButton(
        label: isLoading ? 'Cambiando...' : 'Cambiar',
        icon: LucideIcons.refreshCw,
        onPressed: isLoading ? null : onActionPressed,
        isLoading: isLoading,
        isBooked: true,
      );
    }

    // Class is full
    if (gymClass.status == ClassStatus.full) {
      return _ActionButton(
        label: 'Lleno',
        icon: null,
        onPressed: null,
        isOutlined: true,
        isDisabled: true,
      );
    }

    // Available - show reserve button
    return _ActionButton(
      label: isLoading ? 'Reservando...' : 'Reservar',
      icon: LucideIcons.calendarPlus,
      onPressed: isLoading ? null : onActionPressed,
      isLoading: isLoading,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.isBooked = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isDisabled;
  final bool isBooked;

  @override
  Widget build(BuildContext context) {
    // User is booked - show outlined button with icon
    if (isBooked) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textPrimary,
          backgroundColor: GymGoColors.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          side: const BorderSide(
            color: GymGoColors.cardBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GymGoColors.textPrimary,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 14),
            if (icon != null || isLoading) const SizedBox(width: 6),
            Text(
              label,
              style: GymGoTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Disabled or outlined
    if (isOutlined || isDisabled) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          side: const BorderSide(
            color: GymGoColors.cardBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
        ),
        child: Text(
          label,
          style: GymGoTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: GymGoColors.textTertiary,
          ),
        ),
      );
    }

    // Primary action button
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: GymGoColors.primary,
        foregroundColor: GymGoColors.background,
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.md,
          vertical: GymGoSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GymGoColors.background,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 14),
          if (icon != null || isLoading) const SizedBox(width: 6),
          Text(
            label,
            style: GymGoTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for ClassSessionCard
class ClassSessionCardShimmer extends StatelessWidget {
  const ClassSessionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GymGoColors.cardBackground,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        border: Border.all(color: GymGoColors.cardBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: GymGoColors.shimmerBase,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header shimmer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: GymGoColors.shimmerBase,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: GymGoSpacing.md),
                    Container(
                      height: 28,
                      width: 50,
                      decoration: BoxDecoration(
                        color: GymGoColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GymGoSpacing.sm),
                // Instructor shimmer
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: GymGoColors.shimmerBase,
                    borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                  ),
                ),
                const SizedBox(height: GymGoSpacing.md),
                // Avatars shimmer grid
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(12, (index) {
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: GymGoColors.shimmerBase,
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: GymGoSpacing.md),
                // Button shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 36,
                      width: 100,
                      decoration: BoxDecoration(
                        color: GymGoColors.shimmerBase,
                        borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
