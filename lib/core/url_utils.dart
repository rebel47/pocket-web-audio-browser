import 'constants.dart';

abstract final class UrlUtils {
  static final RegExp _httpScheme = RegExp(r'^https?://', caseSensitive: false);
  static final RegExp _whitespace = RegExp(r'\s');

  static String normalizeInputToUrl(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return AppConstants.defaultHomeUrl;
    }

    if (_httpScheme.hasMatch(trimmed)) {
      return trimmed;
    }

    if (isLikelyUrl(trimmed)) {
      return 'https://$trimmed';
    }

    return Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/search',
      queryParameters: {'q': trimmed},
    ).toString();
  }

  static bool isLikelyUrl(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty || _whitespace.hasMatch(trimmed)) {
      return false;
    }

    final candidate = _httpScheme.hasMatch(trimmed)
        ? Uri.tryParse(trimmed)
        : Uri.tryParse('https://$trimmed');

    if (candidate == null || candidate.host.isEmpty) {
      return false;
    }

    final hostParts = candidate.host.split('.');
    return hostParts.length > 1 && hostParts.every((part) => part.isNotEmpty);
  }
}
