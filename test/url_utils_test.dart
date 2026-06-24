import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_web_audio_browser/core/constants.dart';
import 'package:pocket_web_audio_browser/core/url_utils.dart';

void main() {
  group('UrlUtils.normalizeInputToUrl', () {
    test('keeps full http and https URLs', () {
      expect(
        UrlUtils.normalizeInputToUrl('https://youtube.com/watch?v=abc'),
        'https://youtube.com/watch?v=abc',
      );
      expect(
        UrlUtils.normalizeInputToUrl('http://example.com'),
        'http://example.com',
      );
    });

    test('adds https to likely URLs', () {
      expect(
        UrlUtils.normalizeInputToUrl('example.com'),
        'https://example.com',
      );
      expect(
        UrlUtils.normalizeInputToUrl('youtube.com/watch?v=abc'),
        'https://youtube.com/watch?v=abc',
      );
    });

    test('uses Google search for plain text', () {
      expect(
        UrlUtils.normalizeInputToUrl('flutter webview audio'),
        'https://www.google.com/search?q=flutter+webview+audio',
      );
    });

    test('uses the default homepage for empty input', () {
      expect(UrlUtils.normalizeInputToUrl('  '), AppConstants.defaultHomeUrl);
    });
  });
}
