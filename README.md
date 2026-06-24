# Pocket Web Audio Browser

A lightweight, Android-only personal browser built with Flutter that keeps media (audio/video) playing even when the screen is off or the app is backgrounded.

## Features

- **Background audio playback** — music, podcasts, and YouTube audio continue playing when you lock your screen or switch apps
- **Persistent visibility spoofing** — injected JavaScript tricks sites into thinking the page is always visible, preventing auto-pause on tab-switch or screen-off
- **Smart address bar** — type a full URL to navigate directly, or type any search term to search via Google
- **Persistent state** — remembers your last visited URL across app restarts via `SharedPreferences`
- **Configurable home page** — set any URL as your home page (defaults to `https://youtube.com`)
- **Full-featured WebView** — DOM storage, third-party cookies, inline media, iframes, and Picture-in-Picture support enabled out of the box
- **Minimal UI** — clean Material 3 toolbar with back, forward, home, and refresh controls

## Screenshots

> _Add screenshots here_

## Requirements

| Tool    | Version   |
|---------|-----------|
| Flutter | ≥ 3.x     |
| Dart    | ≥ 3.9.0   |
| Android | API 21+   |

> **iOS / Web / Desktop are not supported.** The app is intentionally Android-only.

## Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/rebel47/pocket-web-audio-browser.git
   cd pocket-web-audio-browser
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on a connected Android device or emulator**
   ```bash
   flutter run
   ```

4. **Build a release APK**
   ```bash
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

```
lib/
├── main.dart                   # Entry point — portrait lock, app bootstrap
├── app.dart                    # MaterialApp with Material 3 theme
├── core/
│   ├── constants.dart          # App-wide constants (name, default URL, search base)
│   └── url_utils.dart          # URL / search-term parsing helpers
├── features/
│   └── browser/
│       ├── browser_page.dart   # Main WebView page (StatefulWidget)
│       ├── browser_controller.dart  # Business logic (navigation, URL handling)
│       ├── browser_state.dart  # Immutable UI state model
│       └── widgets/
│           ├── address_bar.dart        # URL / search input field
│           ├── browser_toolbar.dart    # Back / Forward / Home / Refresh bar
│           └── loading_progress_bar.dart  # Top loading indicator
└── services/
    └── preferences_service.dart  # SharedPreferences wrapper (last URL, home URL)
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| [`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview) | Advanced WebView with background audio & JS injection support |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Persistent storage for last URL and home URL |

## How Background Audio Works

`flutter_inappwebview` is configured with `allowBackgroundAudioPlaying: true` and `mediaPlaybackRequiresUserGesture: false`. On top of that, a `UserScript` injected at `AT_DOCUMENT_START` overrides `document.hidden`, `document.visibilityState`, and `document.hasFocus` so that sites never detect the app going to the background — preventing them from pausing playback.

## License

MIT — see [LICENSE](LICENSE) for details.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
