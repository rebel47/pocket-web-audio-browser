import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'features/browser/browser_page.dart';

class PocketWebAudioBrowserApp extends StatelessWidget {
  const PocketWebAudioBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const BrowserPage(),
    );
  }
}
