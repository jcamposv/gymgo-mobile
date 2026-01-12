import 'dart:io';
import 'dart:typed_data';
import 'member.dart';

/// Normalized state for profile photo selection
/// Represents the three possible states:
/// - none: No photo selected (use fallback)
/// - avatar: Predefined avatar selected
/// - upload: Custom image uploaded from device
sealed class ProfilePhotoSelection {
  const ProfilePhotoSelection();

  /// No photo selected - will use initials fallback
  const factory ProfilePhotoSelection.none() = ProfilePhotoNone;

  /// Predefined avatar selected
  const factory ProfilePhotoSelection.avatar(String avatarPath) = ProfilePhotoAvatar;

  /// Custom image uploaded from device
  const factory ProfilePhotoSelection.upload({
    required File file,
    Uint8List? previewBytes,
  }) = ProfilePhotoUpload;

  /// Create selection from member's current state
  static ProfilePhotoSelection fromMember(Member member) {
    if (member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty) {
      // Member has uploaded image - can't recreate File, so return none
      // The current state will be shown, but for editing we start fresh
      return const ProfilePhotoNone();
    }
    if (member.avatarPath != null && member.avatarPath!.isNotEmpty) {
      return ProfilePhotoSelection.avatar(member.avatarPath!);
    }
    return const ProfilePhotoNone();
  }

  /// Check if this selection represents a change from the member's current state
  bool hasChangesFrom(Member member) {
    return switch (this) {
      ProfilePhotoNone() =>
          (member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty) ||
          (member.avatarPath != null && member.avatarPath!.isNotEmpty),
      ProfilePhotoAvatar(avatarPath: final path) =>
          member.avatarPath != path ||
          (member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty),
      ProfilePhotoUpload() => true, // New upload is always a change
    };
  }

  /// Get display-friendly type name
  String get typeName => switch (this) {
        ProfilePhotoNone() => 'none',
        ProfilePhotoAvatar() => 'avatar',
        ProfilePhotoUpload() => 'upload',
      };

  /// Pattern matching helpers
  T when<T>({
    required T Function() none,
    required T Function(String avatarPath) avatar,
    required T Function(File file, Uint8List? previewBytes) upload,
  }) {
    return switch (this) {
      ProfilePhotoNone() => none(),
      ProfilePhotoAvatar(avatarPath: final path) => avatar(path),
      ProfilePhotoUpload(file: final f, previewBytes: final bytes) => upload(f, bytes),
    };
  }

  T maybeWhen<T>({
    T Function()? none,
    T Function(String avatarPath)? avatar,
    T Function(File file, Uint8List? previewBytes)? upload,
    required T Function() orElse,
  }) {
    return switch (this) {
      ProfilePhotoNone() => none?.call() ?? orElse(),
      ProfilePhotoAvatar(avatarPath: final path) => avatar?.call(path) ?? orElse(),
      ProfilePhotoUpload(file: final f, previewBytes: final bytes) =>
          upload?.call(f, bytes) ?? orElse(),
    };
  }

  /// Check if selection is none
  bool get isNone => this is ProfilePhotoNone;

  /// Check if selection is avatar
  bool get isAvatar => this is ProfilePhotoAvatar;

  /// Check if selection is upload
  bool get isUpload => this is ProfilePhotoUpload;
}

/// No photo selected state
final class ProfilePhotoNone extends ProfilePhotoSelection {
  const ProfilePhotoNone();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePhotoNone && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'ProfilePhotoSelection.none()';
}

/// Avatar selected state
final class ProfilePhotoAvatar extends ProfilePhotoSelection {
  const ProfilePhotoAvatar(this.avatarPath);

  final String avatarPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePhotoAvatar &&
          runtimeType == other.runtimeType &&
          avatarPath == other.avatarPath;

  @override
  int get hashCode => avatarPath.hashCode;

  @override
  String toString() => 'ProfilePhotoSelection.avatar($avatarPath)';
}

/// Custom upload state
final class ProfilePhotoUpload extends ProfilePhotoSelection {
  const ProfilePhotoUpload({
    required this.file,
    this.previewBytes,
  });

  final File file;
  final Uint8List? previewBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePhotoUpload &&
          runtimeType == other.runtimeType &&
          file.path == other.file.path;

  @override
  int get hashCode => file.path.hashCode;

  @override
  String toString() => 'ProfilePhotoSelection.upload(${file.path})';
}
