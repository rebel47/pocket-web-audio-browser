import 'package:flutter/material.dart';

class LoadingProgressBar extends StatelessWidget {
  const LoadingProgressBar({
    required this.progress,
    required this.visible,
    super.key,
  });

  final double progress;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: visible ? 1 : 0,
        child: LinearProgressIndicator(
          value: progress <= 0 || progress >= 1 ? null : progress,
        ),
      ),
    );
  }
}
