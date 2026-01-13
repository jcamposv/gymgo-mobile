import '../../../core/config/env_config.dart';

/// Type of media available for an exercise
enum ExerciseMediaType {
  gif,
  video,
  youtubeVideo,
  none,
}

/// Resolved exercise media with type and URL
class ExerciseMedia {
  const ExerciseMedia({
    required this.type,
    this.url,
    this.thumbnailUrl,
    this.youtubeVideoId,
  });

  final ExerciseMediaType type;
  final String? url;
  final String? thumbnailUrl;
  final String? youtubeVideoId;

  /// No media available
  static const none = ExerciseMedia(type: ExerciseMediaType.none);

  /// Check if media is available
  bool get hasMedia => type != ExerciseMediaType.none && url != null;

  /// Check if this is a YouTube video
  bool get isYouTube => type == ExerciseMediaType.youtubeVideo;

  /// Get YouTube embed URL
  String? get youtubeEmbedUrl {
    if (youtubeVideoId == null) return null;
    return 'https://www.youtube.com/embed/$youtubeVideoId';
  }

  /// Get YouTube thumbnail URL
  String? get youtubeThumbnail {
    if (youtubeVideoId == null) return null;
    return 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';
  }
}

/// Utility class for resolving exercise media URLs
/// Mirrors the web admin's media handling logic
class ExerciseMediaResolver {
  ExerciseMediaResolver._();

  /// Supabase storage base URL
  static String get _storageBaseUrl =>
      '${EnvConfig.supabaseUrl}/storage/v1/object/public';

  /// Resolve the best available media for an exercise
  /// Priority: video > gif (in detail view) or gif > video (in list preview)
  static ExerciseMedia resolveMedia({
    String? gifUrl,
    String? videoUrl,
    String? thumbnailUrl,
    bool preferVideo = false,
  }) {
    final resolvedGif = resolveUrl(gifUrl);
    final resolvedVideo = resolveUrl(videoUrl);
    final resolvedThumbnail = resolveUrl(thumbnailUrl);

    // Check for YouTube video
    final youtubeId = extractYoutubeVideoId(videoUrl);
    final isYouTube = youtubeId != null;

    if (preferVideo) {
      // Detail view: prefer video
      if (resolvedVideo != null || isYouTube) {
        return ExerciseMedia(
          type: isYouTube ? ExerciseMediaType.youtubeVideo : ExerciseMediaType.video,
          url: resolvedVideo,
          thumbnailUrl: resolvedThumbnail ?? resolvedGif,
          youtubeVideoId: youtubeId,
        );
      }
      if (resolvedGif != null) {
        return ExerciseMedia(
          type: ExerciseMediaType.gif,
          url: resolvedGif,
          thumbnailUrl: resolvedThumbnail,
        );
      }
    } else {
      // List view: prefer gif for preview
      if (resolvedGif != null) {
        return ExerciseMedia(
          type: ExerciseMediaType.gif,
          url: resolvedGif,
          thumbnailUrl: resolvedThumbnail,
        );
      }
      if (resolvedVideo != null || isYouTube) {
        return ExerciseMedia(
          type: isYouTube ? ExerciseMediaType.youtubeVideo : ExerciseMediaType.video,
          url: resolvedVideo,
          thumbnailUrl: resolvedThumbnail,
          youtubeVideoId: youtubeId,
        );
      }
    }

    return ExerciseMedia.none;
  }

  /// Resolve a media URL, handling relative paths and various URL formats
  /// Returns null if the URL is invalid or empty
  static String? resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    final trimmed = url.trim();

    // Already a full URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Relative path from Supabase storage
    if (trimmed.startsWith('/')) {
      // Handle /storage/v1/object/public/ prefix
      if (trimmed.contains('/storage/v1/object/public/')) {
        return '${EnvConfig.supabaseUrl}$trimmed';
      }
      // Handle bucket paths like /exercises_bucket/...
      return '$_storageBaseUrl$trimmed';
    }

    // Bucket path without leading slash
    if (trimmed.startsWith('exercises_bucket/') ||
        trimmed.startsWith('avatars/') ||
        trimmed.startsWith('uploads/')) {
      return '$_storageBaseUrl/$trimmed';
    }

    // If it looks like an S3 key or other path, try to construct URL
    if (!trimmed.contains('://') && trimmed.contains('/')) {
      return '$_storageBaseUrl/exercises_bucket/$trimmed';
    }

    // Return as-is if nothing else matches
    return trimmed;
  }

  /// Extract YouTube video ID from various YouTube URL formats
  /// Supports:
  /// - https://www.youtube.com/watch?v=VIDEO_ID
  /// - https://youtu.be/VIDEO_ID
  /// - https://www.youtube.com/embed/VIDEO_ID
  /// - https://youtube.com/shorts/VIDEO_ID
  static String? extractYoutubeVideoId(String? url) {
    if (url == null || url.isEmpty) return null;

    final trimmed = url.trim();

    // Check if it's a YouTube URL
    if (!trimmed.contains('youtube.com') && !trimmed.contains('youtu.be')) {
      return null;
    }

    try {
      final uri = Uri.parse(trimmed);

      // youtube.com/watch?v=VIDEO_ID
      if (uri.host.contains('youtube.com') && uri.path == '/watch') {
        return uri.queryParameters['v'];
      }

      // youtu.be/VIDEO_ID
      if (uri.host == 'youtu.be') {
        final path = uri.path;
        if (path.length > 1) {
          return path.substring(1).split('?').first;
        }
      }

      // youtube.com/embed/VIDEO_ID
      if (uri.path.startsWith('/embed/')) {
        return uri.path.substring(7).split('?').first;
      }

      // youtube.com/shorts/VIDEO_ID
      if (uri.path.startsWith('/shorts/')) {
        return uri.path.substring(8).split('?').first;
      }

      // youtube.com/v/VIDEO_ID
      if (uri.path.startsWith('/v/')) {
        return uri.path.substring(3).split('?').first;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Check if a URL is a YouTube video
  static bool isYoutubeUrl(String? url) {
    return extractYoutubeVideoId(url) != null;
  }

  /// Get video URL for playback (converts YouTube to embed format)
  static String? getPlayableVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return null;

    final youtubeId = extractYoutubeVideoId(videoUrl);
    if (youtubeId != null) {
      // YouTube videos need special handling (use youtube_player_flutter or webview)
      // For now, return the embed URL
      return 'https://www.youtube.com/embed/$youtubeId';
    }

    return resolveUrl(videoUrl);
  }
}
