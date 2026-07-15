import 'package:flutter_test/flutter_test.dart';
import 'package:streaklearn/core/utils/unsplash_url.dart';

void main() {
  group('upgradeUnsplashUrl', () {
    test('rewrites Unsplash thumbnails to a high-res variant', () {
      final upgraded = upgradeUnsplashUrl(
        'https://images.unsplash.com/photo-1618401471353-b98aedd07871?w=200',
      );

      final uri = Uri.parse(upgraded);
      expect(uri.host, 'images.unsplash.com');
      expect(uri.path, '/photo-1618401471353-b98aedd07871');
      expect(uri.queryParameters['w'], '1200');
      expect(uri.queryParameters['q'], '80');
      expect(uri.queryParameters['auto'], 'format');
      expect(uri.queryParameters['fit'], 'crop');
    });

    test('honours custom width and quality', () {
      final upgraded = upgradeUnsplashUrl(
        'https://images.unsplash.com/photo-123?w=200',
        width: 800,
        quality: 60,
      );

      final uri = Uri.parse(upgraded);
      expect(uri.queryParameters['w'], '800');
      expect(uri.queryParameters['q'], '60');
    });

    test('leaves non-Unsplash URLs unchanged', () {
      const url = 'https://example.com/image.png?w=200';
      expect(upgradeUnsplashUrl(url), url);
    });

    test('leaves malformed URLs unchanged', () {
      const url = '::not a url::';
      expect(upgradeUnsplashUrl(url), url);
    });
  });
}
