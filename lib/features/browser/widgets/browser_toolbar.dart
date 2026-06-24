import 'package:flutter/material.dart';

class BrowserToolbar extends StatelessWidget {
  const BrowserToolbar({
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onHome,
    required this.onSettings,
    super.key,
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onHome;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 4,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: canGoBack ? onBack : null,
                icon: const Icon(Icons.arrow_back),
              ),
              IconButton(
                tooltip: 'Forward',
                onPressed: canGoForward ? onForward : null,
                icon: const Icon(Icons.arrow_forward),
              ),
              IconButton(
                tooltip: 'Reload',
                onPressed: onReload,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Home',
                onPressed: onHome,
                icon: const Icon(Icons.home_outlined),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
