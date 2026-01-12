/// Predefined avatar options for member profile photos
///
/// These can be local assets or remote URLs depending on the app setup.
/// For consistency with web, we use paths that match the web avatar structure.
class AvatarConfig {
  AvatarConfig._();

  /// List of available avatar paths
  /// Format: 'avatar_2/name.svg' which maps to local assets
  static const List<String> avatars = [
    'avatar_2/avatar_01.svg',
    'avatar_2/avatar_02.svg',
    'avatar_2/avatar_03.svg',
    'avatar_2/avatar_04.svg',
    'avatar_2/avatar_05.svg',
    'avatar_2/avatar_06.svg',
    'avatar_2/avatar_07.svg',
    'avatar_2/avatar_08.svg',
    'avatar_2/avatar_09.svg',
    'avatar_2/avatar_10.svg',
  ];

  /// Get avatar categories for grouped display (single category for simplicity)
  static const Map<String, List<String>> avatarsByCategory = {
    'Avatares': [
      'avatar_2/avatar_01.svg',
      'avatar_2/avatar_02.svg',
      'avatar_2/avatar_03.svg',
      'avatar_2/avatar_04.svg',
      'avatar_2/avatar_05.svg',
      'avatar_2/avatar_06.svg',
      'avatar_2/avatar_07.svg',
      'avatar_2/avatar_08.svg',
      'avatar_2/avatar_09.svg',
      'avatar_2/avatar_10.svg',
    ],
  };

  /// Base URL for avatar assets if using remote CDN
  /// Set to null to use local assets
  static const String? avatarBaseUrl = null; // 'https://cdn.gymgo.app/avatars/'

  /// Get the full path/URL for an avatar
  static String getAvatarUrl(String avatarPath) {
    if (avatarBaseUrl != null) {
      return '$avatarBaseUrl$avatarPath';
    }
    // Local asset path
    return 'assets/$avatarPath';
  }

  /// Check if an avatar path is valid
  static bool isValidAvatar(String path) {
    return avatars.contains(path);
  }

  /// Get a display name from avatar path
  static String getAvatarDisplayName(String path) {
    final parts = path.split('/');
    if (parts.isEmpty) return 'Avatar';
    final fileName = parts.last.replaceAll('.svg', '').replaceAll('.png', '');
    return fileName
        .split('-')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

/// Simple avatar data class for UI display
class AvatarOption {
  const AvatarOption({
    required this.path,
    required this.displayName,
    this.category,
  });

  final String path;
  final String displayName;
  final String? category;

  /// Create from path
  factory AvatarOption.fromPath(String path, {String? category}) {
    return AvatarOption(
      path: path,
      displayName: AvatarConfig.getAvatarDisplayName(path),
      category: category,
    );
  }

  /// Get all avatar options
  static List<AvatarOption> get all {
    return AvatarConfig.avatars
        .map((path) => AvatarOption.fromPath(path))
        .toList();
  }

  /// Get avatar options by category
  static Map<String, List<AvatarOption>> get byCategory {
    return AvatarConfig.avatarsByCategory.map(
      (category, paths) => MapEntry(
        category,
        paths.map((p) => AvatarOption.fromPath(p, category: category)).toList(),
      ),
    );
  }
}
