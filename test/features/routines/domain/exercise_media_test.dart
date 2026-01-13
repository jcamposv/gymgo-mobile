import 'package:flutter_test/flutter_test.dart';
import 'package:gymgo_mobile/features/routines/domain/exercise_media.dart';

void main() {
  group('ExerciseMediaResolver', () {
    group('resolveUrl', () {
      test('returns null for empty string', () {
        expect(ExerciseMediaResolver.resolveUrl(''), isNull);
      });

      test('returns null for null input', () {
        expect(ExerciseMediaResolver.resolveUrl(null), isNull);
      });

      test('passes through full https URLs unchanged', () {
        const url = 'https://example.com/image.gif';
        expect(ExerciseMediaResolver.resolveUrl(url), equals(url));
      });

      test('passes through full http URLs unchanged', () {
        const url = 'http://example.com/image.gif';
        expect(ExerciseMediaResolver.resolveUrl(url), equals(url));
      });

      test('handles relative paths with leading slash', () {
        const path = '/exercises_bucket/org123/gifs/exercise.gif';
        final result = ExerciseMediaResolver.resolveUrl(path);
        expect(result, contains('supabase.co'));
        expect(result, contains('storage/v1/object/public'));
        expect(result, endsWith(path));
      });

      test('handles bucket paths without leading slash', () {
        const path = 'exercises_bucket/org123/gifs/exercise.gif';
        final result = ExerciseMediaResolver.resolveUrl(path);
        expect(result, contains('supabase.co'));
        expect(result, contains(path));
      });

      test('handles storage paths with full path', () {
        const path = '/storage/v1/object/public/exercises_bucket/test.gif';
        final result = ExerciseMediaResolver.resolveUrl(path);
        expect(result, contains('supabase.co'));
        expect(result, contains(path));
      });
    });

    group('extractYoutubeVideoId', () {
      test('returns null for empty string', () {
        expect(ExerciseMediaResolver.extractYoutubeVideoId(''), isNull);
      });

      test('returns null for null input', () {
        expect(ExerciseMediaResolver.extractYoutubeVideoId(null), isNull);
      });

      test('returns null for non-YouTube URLs', () {
        expect(
          ExerciseMediaResolver.extractYoutubeVideoId('https://vimeo.com/123'),
          isNull,
        );
      });

      test('extracts ID from youtube.com/watch?v= format', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
        expect(
          ExerciseMediaResolver.extractYoutubeVideoId(url),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('extracts ID from youtu.be/ format', () {
        const url = 'https://youtu.be/dQw4w9WgXcQ';
        expect(
          ExerciseMediaResolver.extractYoutubeVideoId(url),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('extracts ID from youtube.com/embed/ format', () {
        const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
        expect(
          ExerciseMediaResolver.extractYoutubeVideoId(url),
          equals('dQw4w9WgXcQ'),
        );
      });

      test('extracts ID from youtube.com/shorts/ format', () {
        const url = 'https://youtube.com/shorts/abc123xyz';
        expect(
          ExerciseMediaResolver.extractYoutubeVideoId(url),
          equals('abc123xyz'),
        );
      });

      test('handles URL with query parameters after video ID', () {
        const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30';
        expect(
          ExerciseMediaResolver.extractYoutubeVideoId(url),
          equals('dQw4w9WgXcQ'),
        );
      });
    });

    group('isYoutubeUrl', () {
      test('returns true for YouTube URLs', () {
        expect(
          ExerciseMediaResolver.isYoutubeUrl('https://www.youtube.com/watch?v=test'),
          isTrue,
        );
        expect(
          ExerciseMediaResolver.isYoutubeUrl('https://youtu.be/test'),
          isTrue,
        );
      });

      test('returns false for non-YouTube URLs', () {
        expect(
          ExerciseMediaResolver.isYoutubeUrl('https://example.com/video.mp4'),
          isFalse,
        );
      });
    });

    group('resolveMedia', () {
      test('returns none when no media available', () {
        final media = ExerciseMediaResolver.resolveMedia();
        expect(media.type, equals(ExerciseMediaType.none));
        expect(media.hasMedia, isFalse);
      });

      test('prefers gif for list preview (preferVideo: false)', () {
        final media = ExerciseMediaResolver.resolveMedia(
          gifUrl: 'https://example.com/exercise.gif',
          videoUrl: 'https://example.com/exercise.mp4',
          preferVideo: false,
        );
        expect(media.type, equals(ExerciseMediaType.gif));
        expect(media.url, equals('https://example.com/exercise.gif'));
      });

      test('prefers video for detail view (preferVideo: true)', () {
        final media = ExerciseMediaResolver.resolveMedia(
          gifUrl: 'https://example.com/exercise.gif',
          videoUrl: 'https://example.com/exercise.mp4',
          preferVideo: true,
        );
        expect(media.type, equals(ExerciseMediaType.video));
        expect(media.url, equals('https://example.com/exercise.mp4'));
      });

      test('returns YouTube type for YouTube URLs', () {
        final media = ExerciseMediaResolver.resolveMedia(
          videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          preferVideo: true,
        );
        expect(media.type, equals(ExerciseMediaType.youtubeVideo));
        expect(media.isYouTube, isTrue);
        expect(media.youtubeVideoId, equals('dQw4w9WgXcQ'));
      });

      test('returns gif when only gif is available', () {
        final media = ExerciseMediaResolver.resolveMedia(
          gifUrl: 'https://example.com/exercise.gif',
          preferVideo: true,
        );
        expect(media.type, equals(ExerciseMediaType.gif));
      });

      test('returns video when only video is available', () {
        final media = ExerciseMediaResolver.resolveMedia(
          videoUrl: 'https://example.com/exercise.mp4',
          preferVideo: false,
        );
        expect(media.type, equals(ExerciseMediaType.video));
      });
    });

    group('ExerciseMedia', () {
      test('youtubeEmbedUrl returns correct URL', () {
        const media = ExerciseMedia(
          type: ExerciseMediaType.youtubeVideo,
          youtubeVideoId: 'dQw4w9WgXcQ',
        );
        expect(
          media.youtubeEmbedUrl,
          equals('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        );
      });

      test('youtubeThumbnail returns correct URL', () {
        const media = ExerciseMedia(
          type: ExerciseMediaType.youtubeVideo,
          youtubeVideoId: 'dQw4w9WgXcQ',
        );
        expect(
          media.youtubeThumbnail,
          equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'),
        );
      });

      test('hasMedia returns true when URL is present', () {
        const media = ExerciseMedia(
          type: ExerciseMediaType.gif,
          url: 'https://example.com/test.gif',
        );
        expect(media.hasMedia, isTrue);
      });

      test('hasMedia returns false for none type', () {
        expect(ExerciseMedia.none.hasMedia, isFalse);
      });
    });
  });
}
