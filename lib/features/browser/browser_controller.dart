import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/url_utils.dart';
import '../../services/preferences_service.dart';

class BrowserController {
  BrowserController({required PreferencesService preferences})
    : _preferences = preferences;

  final PreferencesService _preferences;
  InAppWebViewController? _webViewController;

  void attach(InAppWebViewController controller) {
    _webViewController = controller;
  }

  Future<String> initialUrl() {
    return _preferences.getLastUrl();
  }

  Future<void> loadInput(String input) {
    return loadUrl(UrlUtils.normalizeInputToUrl(input));
  }

  Future<void> loadUrl(String url) async {
    final controller = _webViewController;

    if (controller == null) {
      return;
    }

    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    await saveVisitedUrl(url);
  }

  Future<void> goHome() async {
    final homeUrl = await _preferences.getHomeUrl();
    await loadUrl(homeUrl);
  }

  Future<void> goBack() async {
    final controller = _webViewController;

    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    }
  }

  Future<void> goForward() async {
    final controller = _webViewController;

    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  Future<void> reload() async {
    await _webViewController?.reload();
  }

  Future<bool> canGoBack() async {
    return await _webViewController?.canGoBack() ?? false;
  }

  Future<bool> canGoForward() async {
    return await _webViewController?.canGoForward() ?? false;
  }

  Future<void> saveVisitedUrl(String url) {
    if (url.isEmpty || url == 'about:blank') {
      return Future.value();
    }

    return _preferences.saveLastUrl(url);
  }
}
