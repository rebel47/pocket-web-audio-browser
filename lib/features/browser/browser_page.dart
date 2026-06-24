import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/constants.dart';
import '../../services/preferences_service.dart';
import 'browser_controller.dart';
import 'browser_state.dart';
import 'widgets/address_bar.dart';
import 'widgets/browser_toolbar.dart';
import 'widgets/loading_progress_bar.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> with WidgetsBindingObserver {
  final GlobalKey _webViewKey = GlobalKey();
  final PreferencesService _preferences = PreferencesService();

  late final BrowserController _browserController = BrowserController(
    preferences: _preferences,
  );

  BrowserState _browserState = const BrowserState(
    currentUrl: AppConstants.defaultHomeUrl,
  );
  String? _initialUrl;
  bool _isPreparing = true;

  static final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    useHybridComposition: true,
    supportMultipleWindows: false,
    domStorageEnabled: true,
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,
    allowBackgroundAudioPlaying: true,
    iframeAllowFullscreen: true,
    allowsPictureInPictureMediaPlayback: true,
  );

  static final UnmodifiableListView<UserScript> _userScripts =
      UnmodifiableListView([
        UserScript(
          source: '''
(function () {
  try {
    Object.defineProperty(document, 'hidden', {
      configurable: true,
      get: function () { return false; }
    });
    Object.defineProperty(document, 'visibilityState', {
      configurable: true,
      get: function () { return 'visible'; }
    });
    document.hasFocus = function () { return true; };
    var stopVisibilityEvent = function (event) {
      event.stopImmediatePropagation();
    };
    document.addEventListener('visibilitychange', stopVisibilityEvent, true);
    document.addEventListener('webkitvisibilitychange', stopVisibilityEvent, true);
  } catch (_) {}
})();
''',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: false,
        ),
      ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadInitialUrl());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Intentionally do not pause or resume the WebView here.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadInitialUrl() async {
    final initialUrl = await _browserController.initialUrl();

    if (!mounted) {
      return;
    }

    setState(() {
      _initialUrl = initialUrl;
      _isPreparing = false;
      _browserState = _browserState.copyWith(currentUrl: initialUrl);
    });
  }

  void _handleSubmittedAddress(String input) {
    unawaited(_browserController.loadInput(input));
  }

  void _handleUrlChanged(WebUri? url, {bool? isLoading, double? progress}) {
    final nextUrl = url?.toString();

    if (!mounted) {
      return;
    }

    setState(() {
      _browserState = _browserState.copyWith(
        currentUrl: nextUrl == null || nextUrl.isEmpty
            ? _browserState.currentUrl
            : nextUrl,
        isLoading: isLoading,
        progress: progress,
      );
    });

    if (nextUrl != null && nextUrl.isNotEmpty) {
      unawaited(_browserController.saveVisitedUrl(nextUrl));
    }
  }

  Future<void> _syncNavigationState() async {
    final canGoBack = await _browserController.canGoBack();
    final canGoForward = await _browserController.canGoForward();

    if (!mounted) {
      return;
    }

    setState(() {
      _browserState = _browserState.copyWith(
        canGoBack: canGoBack,
        canGoForward: canGoForward,
      );
    });
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  PermissionResponse _handlePermissionRequest(PermissionRequest request) {
    final protectedMediaResources = request.resources
        .where(
          (resource) => resource == PermissionResourceType.PROTECTED_MEDIA_ID,
        )
        .toList();

    if (protectedMediaResources.isEmpty) {
      return PermissionResponse(action: PermissionResponseAction.DENY);
    }

    return PermissionResponse(
      resources: protectedMediaResources,
      action: PermissionResponseAction.GRANT,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressVisible =
        _browserState.isLoading || _browserState.progress < 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Material(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AddressBar(
                  text: _browserState.currentUrl,
                  onSubmitted: _handleSubmittedAddress,
                ),
              ),
            ),
            LoadingProgressBar(
              progress: _browserState.progress,
              visible: !_isPreparing && progressVisible,
            ),
            Expanded(
              child: _isPreparing
                  ? const Center(child: CircularProgressIndicator())
                  : InAppWebView(
                      key: _webViewKey,
                      initialUrlRequest: URLRequest(url: WebUri(_initialUrl!)),
                      initialUserScripts: _userScripts,
                      initialSettings: _settings,
                      onWebViewCreated: (controller) {
                        _browserController.attach(controller);
                        unawaited(_syncNavigationState());
                      },
                      onLoadStart: (controller, url) {
                        _handleUrlChanged(url, isLoading: true, progress: 0);
                        unawaited(_syncNavigationState());
                      },
                      onLoadStop: (controller, url) {
                        _handleUrlChanged(url, isLoading: false, progress: 1);
                        unawaited(_syncNavigationState());
                      },
                      onProgressChanged: (controller, progress) {
                        _handleUrlChanged(
                          null,
                          isLoading: progress < 100,
                          progress: progress / 100,
                        );
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                            _handleUrlChanged(url);
                            unawaited(_syncNavigationState());
                          },
                      onEnterFullscreen: (controller) {
                        unawaited(_enterFullscreen());
                      },
                      onExitFullscreen: (controller) {
                        unawaited(_exitFullscreen());
                      },
                      onPermissionRequest: (controller, request) async {
                        return _handlePermissionRequest(request);
                      },
                    ),
            ),
            BrowserToolbar(
              canGoBack: _browserState.canGoBack,
              canGoForward: _browserState.canGoForward,
              onBack: () => unawaited(_browserController.goBack()),
              onForward: () => unawaited(_browserController.goForward()),
              onReload: () => unawaited(_browserController.reload()),
              onHome: () => unawaited(_browserController.goHome()),
            ),
          ],
        ),
      ),
    );
  }
}
