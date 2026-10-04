import 'package:flutter/material.dart';
import '../theme/responsive.dart';

/// Scales all text by the window width, on top of the person's own system
/// text size, so the same app reads well on a small phone and a big monitor.
class TextScaleScope extends StatelessWidget {
  final Widget child;
  const TextScaleScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final factor = Responsive.textFactor(media.size.width);
    final combined = (media.textScaler.scale(1) * factor).clamp(0.8, 2.0);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(combined.toDouble())),
      child: child,
    );
  }
}
