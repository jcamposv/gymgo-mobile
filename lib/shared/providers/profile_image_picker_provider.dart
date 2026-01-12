import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/member.dart';
import '../models/profile_photo_selection.dart';

/// State for profile image picker
class ProfileImagePickerState {
  const ProfileImagePickerState({
    required this.selection,
    required this.originalSelection,
    this.isLoading = false,
    this.error,
    this.previewBytes,
  });

  final ProfilePhotoSelection selection;
  final ProfilePhotoSelection originalSelection;
  final bool isLoading;
  final String? error;
  final Uint8List? previewBytes;

  /// Check if there are unsaved changes
  bool get hasChanges => selection != originalSelection;

  /// Check if can save (has changes and not loading)
  bool get canSave => hasChanges && !isLoading;

  ProfileImagePickerState copyWith({
    ProfilePhotoSelection? selection,
    ProfilePhotoSelection? originalSelection,
    bool? isLoading,
    String? error,
    Uint8List? previewBytes,
    bool clearError = false,
    bool clearPreview = false,
  }) {
    return ProfileImagePickerState(
      selection: selection ?? this.selection,
      originalSelection: originalSelection ?? this.originalSelection,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      previewBytes: clearPreview ? null : (previewBytes ?? this.previewBytes),
    );
  }
}

/// Controller for profile image picker logic
class ProfileImagePickerController extends StateNotifier<ProfileImagePickerState> {
  ProfileImagePickerController({
    required Member member,
    this.maxFileSizeBytes = 5 * 1024 * 1024, // 5MB default
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'webp'],
  }) : super(ProfileImagePickerState(
          selection: ProfilePhotoSelection.fromMember(member),
          originalSelection: ProfilePhotoSelection.fromMember(member),
        ));

  final int maxFileSizeBytes;
  final List<String> allowedExtensions;
  final ImagePicker _imagePicker = ImagePicker();

  /// Select an avatar
  void selectAvatar(String avatarPath) {
    state = state.copyWith(
      selection: ProfilePhotoSelection.avatar(avatarPath),
      clearError: true,
      clearPreview: true,
    );
  }

  /// Remove photo (set to none)
  void removePhoto() {
    state = state.copyWith(
      selection: const ProfilePhotoSelection.none(),
      clearError: true,
      clearPreview: true,
    );
  }

  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  /// Pick image from camera
  Future<void> pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Validate file
      final file = File(pickedFile.path);
      final validationError = await _validateFile(file);

      if (validationError != null) {
        state = state.copyWith(
          isLoading: false,
          error: validationError,
        );
        return;
      }

      // Read preview bytes for display
      final bytes = await file.readAsBytes();

      state = state.copyWith(
        selection: ProfilePhotoSelection.upload(
          file: file,
          previewBytes: bytes,
        ),
        previewBytes: bytes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al seleccionar imagen: ${e.toString()}',
      );
    }
  }

  Future<String?> _validateFile(File file) async {
    // Check file exists
    if (!await file.exists()) {
      return 'El archivo no existe';
    }

    // Check file size
    final size = await file.length();
    if (size > maxFileSizeBytes) {
      final maxMB = maxFileSizeBytes / (1024 * 1024);
      return 'El archivo es muy grande. Máximo ${maxMB.toStringAsFixed(0)}MB';
    }

    // Check extension
    final extension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Formato no soportado. Use: ${allowedExtensions.join(", ")}';
    }

    return null;
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset to original selection
  void reset() {
    state = ProfileImagePickerState(
      selection: state.originalSelection,
      originalSelection: state.originalSelection,
    );
  }

  /// Set loading state (for external save operations)
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Set error (for external save operations)
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Update original selection after successful save
  void confirmSave() {
    state = state.copyWith(
      originalSelection: state.selection,
      isLoading: false,
      clearError: true,
    );
  }
}

/// Provider family for profile image picker
/// Use with a member to create a scoped controller
final profileImagePickerProvider = StateNotifierProvider.autoDispose
    .family<ProfileImagePickerController, ProfileImagePickerState, Member>(
  (ref, member) => ProfileImagePickerController(member: member),
);

/// Simplified provider for when member data is passed directly
/// Use this in the bottom sheet
final profileImagePickerControllerProvider = StateNotifierProvider.autoDispose<
    ProfileImagePickerController, ProfileImagePickerState>(
  (ref) => throw UnimplementedError(
    'profileImagePickerControllerProvider must be overridden with a member',
  ),
);
