import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/gymgo_colors.dart';
import '../../../../core/theme/gymgo_spacing.dart';
import '../../../../core/theme/gymgo_typography.dart';
import '../../../../shared/models/member.dart';
import '../../../../shared/models/profile_photo_selection.dart';
import '../../../../shared/ui/components/components.dart';

/// Example integration of MemberProfilePhoto in a member details header
///
/// This widget demonstrates:
/// 1. Using MemberProfilePhoto with edit functionality
/// 2. Handling the onSave callback with API integration
/// 3. Optimistic UI updates
/// 4. Error handling with revert
class MemberDetailsHeader extends ConsumerStatefulWidget {
  const MemberDetailsHeader({
    super.key,
    required this.member,
    this.onMemberUpdated,
  });

  final Member member;
  final void Function(Member updatedMember)? onMemberUpdated;

  @override
  ConsumerState<MemberDetailsHeader> createState() =>
      _MemberDetailsHeaderState();
}

class _MemberDetailsHeaderState extends ConsumerState<MemberDetailsHeader> {
  late Member _currentMember;
  Member? _previousMember; // For reverting on error

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
  }

  @override
  void didUpdateWidget(covariant MemberDetailsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.member != oldWidget.member) {
      _currentMember = widget.member;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GymGoSpacing.lg),
      decoration: BoxDecoration(
        color: GymGoColors.surface,
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusLg),
        border: Border.all(color: GymGoColors.cardBorder),
      ),
      child: Row(
        children: [
          // Profile photo with edit functionality
          MemberProfilePhoto(
            member: _currentMember,
            size: ProfilePhotoSize.large,
            isEditable: true,
            showEditOverlay: true,
            onSave: _handleSaveProfilePhoto,
            onSavedOptimistic: _handleOptimisticUpdate,
          ),
          const SizedBox(width: GymGoSpacing.lg),
          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentMember.name,
                  style: GymGoTypography.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: GymGoSpacing.xs),
                if (_currentMember.email != null)
                  Text(
                    _currentMember.email!,
                    style: GymGoTypography.bodySmall.copyWith(
                      color: GymGoColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: GymGoSpacing.sm),
                // Membership badge
                if (_currentMember.membershipStatus != null)
                  _MembershipBadge(status: _currentMember.membershipStatus!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Handle optimistic UI update - called immediately on save
  void _handleOptimisticUpdate(ProfilePhotoSelection selection) {
    _previousMember = _currentMember;

    setState(() {
      _currentMember = selection.when(
        none: () => _currentMember.copyWith(
          clearProfileImageUrl: true,
          clearAvatarPath: true,
        ),
        avatar: (path) => _currentMember.copyWith(
          avatarPath: path,
          clearProfileImageUrl: true,
        ),
        upload: (file, bytes) {
          // For upload, we'll update after the actual upload completes
          // Just keep the current state for now
          return _currentMember;
        },
      );
    });
  }

  /// Handle save - called with the selection to persist
  Future<void> _handleSaveProfilePhoto(ProfilePhotoSelection selection) async {
    final supabase = Supabase.instance.client;

    try {
      await selection.when(
        none: () => _removeProfilePhoto(supabase),
        avatar: (path) => _setAvatarPath(supabase, path),
        upload: (file, bytes) => _uploadProfileImage(supabase, file),
      );

      // Notify parent of successful update
      widget.onMemberUpdated?.call(_currentMember);
    } catch (e) {
      // Revert to previous state on error
      if (_previousMember != null) {
        setState(() {
          _currentMember = _previousMember!;
        });
      }
      rethrow;
    }
  }

  Future<void> _removeProfilePhoto(SupabaseClient supabase) async {
    // Update member in database - use avatar_url for consistency with web
    await supabase.from('members').update({
      'avatar_url': null,
    }).eq('id', _currentMember.id);

    setState(() {
      _currentMember = _currentMember.copyWith(
        clearProfileImageUrl: true,
        clearAvatarPath: true,
      );
    });
  }

  Future<void> _setAvatarPath(SupabaseClient supabase, String avatarPath) async {
    // Convert mobile path to web format: avatar_2/avatar_01.svg -> /avatar/avatar_01.svg
    final webAvatarUrl = avatarPath.replaceFirst('avatar_2/', '/avatar/');

    // Update member in database - use avatar_url for consistency with web
    await supabase.from('members').update({
      'avatar_url': webAvatarUrl,
    }).eq('id', _currentMember.id);

    setState(() {
      _currentMember = _currentMember.copyWith(
        avatarPath: avatarPath,
        clearProfileImageUrl: true,
      );
    });
  }

  Future<void> _uploadProfileImage(
    SupabaseClient supabase,
    File file,
  ) async {
    final memberId = _currentMember.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'profile_$memberId\_$timestamp.jpg';
    final storagePath = 'profiles/$memberId/$fileName';

    // Upload to Supabase Storage
    await supabase.storage.from('avatars').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    // Get public URL with cache-busting parameter
    final baseUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);
    final publicUrl = '$baseUrl?v=$timestamp';

    // Update member in database - use avatar_url for consistency with web
    await supabase.from('members').update({
      'avatar_url': publicUrl,
    }).eq('id', _currentMember.id);

    setState(() {
      _currentMember = _currentMember.copyWith(
        profileImageUrl: publicUrl,
        clearAvatarPath: true,
      );
    });
  }
}

class _MembershipBadge extends StatelessWidget {
  const _MembershipBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymGoSpacing.sm,
        vertical: GymGoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? GymGoColors.success.withValues(alpha: 0.15)
            : GymGoColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GymGoSpacing.radiusSm),
      ),
      child: Text(
        isActive ? 'Miembro activo' : 'Membresía: $status',
        style: GymGoTypography.labelSmall.copyWith(
          color: isActive ? GymGoColors.success : GymGoColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
