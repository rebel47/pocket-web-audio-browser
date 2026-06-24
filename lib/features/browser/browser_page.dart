import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/constants.dart';
import '../../services/ad_blocker.dart';
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
  bool _isFullYouTubeMode = false;

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
        // ── Keep page "visible" so background audio never pauses ─────────────
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

        // ── Ad blocker: skip/remove YouTube and generic ads ──────────────────
        UserScript(
          source: r'''
(function () {
  'use strict';

  var AD_ELEMENT_SELECTORS = [
    '.ytp-ad-overlay-container',
    '.ytp-ad-text-overlay',
    '.ytp-ad-image-overlay',
    '.ytp-ad-module',
    '.ytp-suggested-action',
    '.ytp-ad-feedback-dialog-container',
    '#masthead-ad',
    'ytd-banner-promo-renderer',
    'ytd-statement-banner-renderer',
    'ytd-ad-slot-renderer',
    'ytd-in-feed-ad-layout-renderer',
    'ytd-promoted-sparkles-web-renderer',
    'ytd-promoted-video-renderer',
    'ytd-display-ad-renderer',
    'ytd-rich-item-renderer:has(ytd-ad-slot-renderer)',
  ];

  function removeAdElements() {
    AD_ELEMENT_SELECTORS.forEach(function (sel) {
      try {
        document.querySelectorAll(sel).forEach(function (el) {
          el.remove();
        });
      } catch (_) {}
    });
  }

  function handleVideoAd() {
    // Click skip button the moment it appears
    var skipBtn = document.querySelector(
      '.ytp-skip-ad-button, .ytp-ad-skip-button, .ytp-ad-skip-button-modern, ' +
      '.ytp-ad-skip-button-slot button, [class*="skip-ad"]'
    );
    if (skipBtn) {
      skipBtn.click();
      return;
    }

    // For non-skippable ads: mute + seek to end
    var adShowing = document.querySelector(
      '.ad-showing .html5-main-video, ' +
      '.ad-showing video'
    );
    if (adShowing) {
      try {
        adShowing.muted = true;
        if (adShowing.duration && isFinite(adShowing.duration)) {
          adShowing.currentTime = adShowing.duration;
        } else {
          adShowing.playbackRate = 16;
        }
      } catch (_) {}
    }
  }

  function tick() {
    handleVideoAd();
    removeAdElements();
  }

  // Observe DOM mutations — YouTube is a SPA, ads appear dynamically
  try {
    var observer = new MutationObserver(tick);
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  } catch (_) {}

  // Periodic fallback (catches anything the observer misses)
  setInterval(tick, 500);

  // Re-run on YouTube SPA navigation
  window.addEventListener('yt-navigate-finish', tick);
  window.addEventListener('yt-page-data-updated', tick);
})();
''',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          forMainFrameOnly: true,
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
    final results = await Future.wait([
      _browserController.initialUrl(),
      _preferences.getFullYouTubeMode(),
    ]);

    if (!mounted) {
      return;
    }

    final initialUrl = results[0] as String;
    final fullYouTubeMode = results[1] as bool;

    setState(() {
      _initialUrl = initialUrl;
      _isPreparing = false;
      _isFullYouTubeMode = fullYouTubeMode;
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

  void _handleSettings() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Full YouTube Mode'),
                    subtitle: const Text(
                      'Hides the address bar for a cleaner viewing experience',
                    ),
                    secondary: const Icon(Icons.smart_display_outlined),
                    value: _isFullYouTubeMode,
                    onChanged: (value) async {
                      await _preferences.saveFullYouTubeMode(value);
                      setSheetState(() {});
                      setState(() => _isFullYouTubeMode = value);
                      if (value) {
                        unawaited(_browserController.goHome());
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

    final webView = _isPreparing
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
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
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
            shouldInterceptRequest: (controller, request) async {
              if (AdBlocker.shouldBlock(request.url.toString())) {
                return WebResourceResponse(data: Uint8List(0));
              }
              return null;
            },
          );

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main content column ──────────────────────────────────────────
            Column(
              children: [
                if (!_isFullYouTubeMode)
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
                Expanded(child: webView),
                if (!_isFullYouTubeMode)
                  BrowserToolbar(
                    canGoBack: _browserState.canGoBack,
                    canGoForward: _browserState.canGoForward,
                    onBack: () => unawaited(_browserController.goBack()),
                    onForward: () => unawaited(_browserController.goForward()),
                    onReload: () => unawaited(_browserController.reload()),
                    onHome: () => unawaited(_browserController.goHome()),
                    onSettings: _handleSettings,
                  ),
              ],
            ),

            // ── Full-YouTube-Mode floating settings pill ─────────────────────
            if (_isFullYouTubeMode)
              Positioned(
                bottom: 20,
                right: 16,
                child: Opacity(
                  opacity: 0.38,
                  child: Material(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _handleSettings,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
