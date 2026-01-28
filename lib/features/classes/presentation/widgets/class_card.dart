import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/gym_class.dart';

/// Class card matching the reference design with:
/// - Left accent border (lime when booked, gray otherwise)
/// - Class name UPPERCASE with time on right
/// - Avatars grid showing capacity slots
/// - Cambiar/Reservar action button
class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.gymClass,
    required this.onReserve,
    required this.onCancel,
    this.isLoading = false,
  });

  final GymClass gymClass;
  final VoidCallback onReserve;
  final VoidCallback onCancel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Stack(
        children: [
          // Main card content
          GymGoCard(
            padding: const EdgeInsets.all(GymGoSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Class name UPPERCASE + Time
                _buildHeader(),
                const SizedBox(height: GymGoSpacing.sm),

                // Instructor info
                _buildInstructorInfo(),
                const SizedBox(height: GymGoSpacing.md),

                // Avatars grid with capacity slots
                _buildAvatarsGrid(),
                const SizedBox(height: GymGoSpacing.md),

                // Footer with capacity and action button
                _buildFooter(),
              ],
            ),
          ),
          // Left accent border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: gymClass.isUserBooked
                    ? GymGoColors.primary
                    : GymGoColors.textTertiary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(GymGoSpacing.radiusLg),
                  bottomLeft: Radius.circular(GymGoSpacing.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class name UPPERCASE
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
        // Instructor logo placeholder
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
          child: const Center(
            child: Icon(
              LucideIcons.dumbbell,
              size: 16,
              color: GymGoColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        // Instructor name and location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gymClass.instructorName,
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
              Text(
                gymClass.location,
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarsGrid() {
    final capacity = gymClass.maxCapacity;
    final enrolled = gymClass.currentParticipants;
    final participants = gymClass.participants;

    // Show max 18 slots visible
    final maxVisible = capacity > 18 ? 18 : capacity;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(maxVisible, (index) {
        final isEnrolled = index < enrolled;
        final hasParticipant = index < participants.length;
        final participant = hasParticipant ? participants[index] : null;

        return _ParticipantSlot(
          isEnrolled: isEnrolled,
          participant: participant,
        );
      }),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Capacity info
        Expanded(
          child: Text(
            '${gymClass.currentParticipants}/${gymClass.maxCapacity} inscritos',
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ),
        // Action button wrapped to compute intrinsic width
        IntrinsicWidth(
          child: _buildActionButton(),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // Class is finished
    if (gymClass.status == ClassStatus.finished) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          side: const BorderSide(color: GymGoColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
        ),
        child: const Text('Finalizada'),
      );
    }

    // User is already booked - show "Cambiar" button
    if (gymClass.isUserBooked) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textPrimary,
          backgroundColor: GymGoColors.surface,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          side: const BorderSide(color: GymGoColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GymGoColors.textPrimary,
                ),
              )
            : const Icon(LucideIcons.refreshCw, size: 14),
        label: Text(isLoading ? 'Cambiando...' : 'Cambiar'),
      );
    }

    // Class is full
    if (gymClass.status == ClassStatus.full) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: GymGoColors.textTertiary,
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.md,
            vertical: GymGoSpacing.sm,
          ),
          side: const BorderSide(color: GymGoColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
          ),
        ),
        child: const Text('Lleno'),
      );
    }

    // Available - show reserve button
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onReserve,
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
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GymGoColors.background,
              ),
            )
          : const Icon(LucideIcons.calendarPlus, size: 14),
      label: Text(isLoading ? 'Reservando...' : 'Reservar'),
    );
  }
}

/// Individual participant slot with avatar and tap-to-expand
class _ParticipantSlot extends StatelessWidget {
  const _ParticipantSlot({
    required this.isEnrolled,
    this.participant,
  });

  final bool isEnrolled;
  final ClassParticipant? participant;

  @override
  Widget build(BuildContext context) {
    if (!isEnrolled) {
      return _buildEmptySlot();
    }

    final hasAvatar = participant?.avatarUrl != null && participant!.avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: participant != null ? () => _showParticipantDialog(context) : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
          color: GymGoColors.surface,
          border: Border.all(
            color: GymGoColors.cardBorder,
            width: 1,
          ),
        ),
        child: hasAvatar
            ? ClipRRect(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm - 1),
                child: CachedNetworkImage(
                  imageUrl: participant!.avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildEnrolledPlaceholder(),
                  errorWidget: (_, __, ___) => _buildEnrolledPlaceholder(),
                ),
              )
            : _buildEnrolledPlaceholder(),
      ),
    );
  }

  void _showParticipantDialog(BuildContext context) {
    HapticFeedback.lightImpact();

    final hasAvatar = participant?.avatarUrl != null && participant!.avatarUrl!.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd),
                color: GymGoColors.surface,
                border: Border.all(
                  color: GymGoColors.primary,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusMd - 2),
                child: hasAvatar
                    ? CachedNetworkImage(
                        imageUrl: participant!.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildLargePlaceholder(),
                        errorWidget: (_, __, ___) => _buildLargePlaceholder(),
                      )
                    : _buildLargePlaceholder(),
              ),
            ),
            const SizedBox(height: GymGoSpacing.md),
            // Name
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GymGoSpacing.md,
                vertical: GymGoSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: GymGoColors.cardBackground,
                borderRadius: BorderRadius.circular(GymGoSpacing.radiusFull),
              ),
              child: Text(
                participant?.name ?? 'Miembro',
                style: GymGoTypography.labelMedium.copyWith(
                  color: GymGoColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledPlaceholder() {
    return const Center(
      child: Icon(
        LucideIcons.user,
        size: 20,
        color: GymGoColors.textTertiary,
      ),
    );
  }

  Widget _buildLargePlaceholder() {
    return Container(
      color: GymGoColors.surfaceLight,
      child: const Center(
        child: Icon(
          LucideIcons.user,
          size: 48,
          color: GymGoColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        color: GymGoColors.cardBackground,
        border: Border.all(
          color: GymGoColors.cardBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: GymGoColors.cardBorder.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
