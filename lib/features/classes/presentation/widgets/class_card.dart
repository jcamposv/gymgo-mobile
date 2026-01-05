import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/ui/components/components.dart';
import '../../domain/gym_class.dart';

/// Class card displaying class info with avatar grid and booking state
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
    return GymGoCard(
      padding: const EdgeInsets.all(GymGoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Time + Status badge
          _buildHeader(),
          const SizedBox(height: GymGoSpacing.md),

          // Class name and instructor
          _buildClassInfo(),
          const SizedBox(height: GymGoSpacing.md),

          // Participants section
          _buildParticipantsSection(),
          const SizedBox(height: GymGoSpacing.md),

          // Action button
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Time
        Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: GymGoColors.textSecondary,
            ),
            const SizedBox(width: GymGoSpacing.xs),
            Text(
              '${gymClass.startTime} - ${gymClass.endTime}',
              style: GymGoTypography.labelLarge.copyWith(
                color: GymGoColors.textPrimary,
              ),
            ),
          ],
        ),
        // Status badge
        _StatusBadge(status: gymClass.status, isUserBooked: gymClass.isUserBooked),
      ],
    );
  }

  Widget _buildClassInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gymClass.name,
          style: GymGoTypography.headlineSmall,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              LucideIcons.user,
              size: 14,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              gymClass.instructorName,
              style: GymGoTypography.bodySmall.copyWith(
                color: GymGoColors.textSecondary,
              ),
            ),
            const SizedBox(width: GymGoSpacing.md),
            Icon(
              LucideIcons.mapPin,
              size: 14,
              color: GymGoColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                gymClass.location,
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    final spotsLeft = gymClass.maxCapacity - gymClass.currentParticipants;
    final isFull = spotsLeft <= 0;
    final isAlmostFull = spotsLeft <= 3 && spotsLeft > 0;

    return Row(
      children: [
        // Avatar stack
        if (gymClass.participantAvatars.isNotEmpty) ...[
          _AvatarStack(avatars: gymClass.participantAvatars),
          const SizedBox(width: GymGoSpacing.sm),
        ],
        // Capacity info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${gymClass.currentParticipants}/${gymClass.maxCapacity} inscritos',
                style: GymGoTypography.bodySmall.copyWith(
                  color: GymGoColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: gymClass.currentParticipants / gymClass.maxCapacity,
                  backgroundColor: GymGoColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull
                        ? GymGoColors.error
                        : isAlmostFull
                            ? GymGoColors.warning
                            : GymGoColors.primary,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: GymGoSpacing.sm),
        // Spots left badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isFull
                ? GymGoColors.error.withValues(alpha: 0.15)
                : isAlmostFull
                    ? GymGoColors.warning.withValues(alpha: 0.15)
                    : GymGoColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
          ),
          child: Text(
            isFull
                ? 'Lleno'
                : '$spotsLeft ${spotsLeft == 1 ? 'lugar' : 'lugares'}',
            style: GymGoTypography.labelSmall.copyWith(
              color: isFull
                  ? GymGoColors.error
                  : isAlmostFull
                      ? GymGoColors.warning
                      : GymGoColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    // Class is finished
    if (gymClass.status == ClassStatus.finished) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: GymGoColors.cardBorder),
          ),
          child: Text(
            'Clase finalizada',
            style: GymGoTypography.labelMedium.copyWith(
              color: GymGoColors.textTertiary,
            ),
          ),
        ),
      );
    }

    // User is already booked - show cancel button
    if (gymClass.isUserBooked) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onCancel,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GymGoColors.error,
                  ),
                )
              : const Icon(LucideIcons.x, size: 16),
          label: Text(isLoading ? 'Cancelando...' : 'Cancelar reserva'),
          style: OutlinedButton.styleFrom(
            foregroundColor: GymGoColors.error,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(
              color: GymGoColors.error.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    // Class is full - show waitlist or disabled button
    if (gymClass.status == ClassStatus.full) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(LucideIcons.userPlus, size: 16),
          label: const Text('Clase llena'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: GymGoColors.cardBorder),
          ),
        ),
      );
    }

    // Available - show reserve button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onReserve,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: GymGoColors.background,
                ),
              )
            : const Icon(LucideIcons.calendarPlus, size: 16),
        label: Text(isLoading ? 'Reservando...' : 'Reservar lugar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: GymGoColors.primary,
          foregroundColor: GymGoColors.background,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.isUserBooked,
  });

  final ClassStatus status;
  final bool isUserBooked;

  @override
  Widget build(BuildContext context) {
    if (isUserBooked) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GymGoSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: GymGoColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 12,
              color: GymGoColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Reservado',
              style: GymGoTypography.labelSmall.copyWith(
                color: GymGoColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    switch (status) {
      case ClassStatus.available:
        return const SizedBox.shrink();
      case ClassStatus.full:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: GymGoColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
          ),
          child: Text(
            'Lleno',
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case ClassStatus.finished:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymGoSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: GymGoColors.textTertiary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
          ),
          child: Text(
            'Finalizada',
            style: GymGoTypography.labelSmall.copyWith(
              color: GymGoColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 28.0;
    const overlap = 8.0;
    final displayCount = avatars.length > 4 ? 4 : avatars.length;
    final remainingCount = avatars.length - displayCount;

    return SizedBox(
      width: avatarSize + (displayCount - 1) * (avatarSize - overlap) + (remainingCount > 0 ? avatarSize - overlap : 0),
      height: avatarSize,
      child: Stack(
        children: [
          ...List.generate(displayCount, (index) {
            return Positioned(
              left: index * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GymGoColors.surface,
                    width: 2,
                  ),
                  color: GymGoColors.cardBorder,
                ),
                child: ClipOval(
                  child: avatars[index].isNotEmpty
                      ? Image.network(
                          avatars[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                        )
                      : _buildPlaceholderAvatar(),
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: displayCount * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GymGoColors.surface,
                    width: 2,
                  ),
                  color: GymGoColors.primary.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: GymGoTypography.labelSmall.copyWith(
                      color: GymGoColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: GymGoColors.cardBorder,
      child: const Icon(
        LucideIcons.user,
        size: 14,
        color: GymGoColors.textTertiary,
      ),
    );
  }
}
