class BrowserState {
  const BrowserState({
    required this.currentUrl,
    this.progress = 0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isLoading = false,
  });

  final String currentUrl;
  final double progress;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;

  BrowserState copyWith({
    String? currentUrl,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
    bool? isLoading,
  }) {
    return BrowserState(
      currentUrl: currentUrl ?? this.currentUrl,
      progress: progress ?? this.progress,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
