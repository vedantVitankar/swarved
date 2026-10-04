import 'package:flutter/material.dart';
import '../theme/typography.dart';
import 'sun_mark.dart';

/// Stands in for a tab whose real screen hasn't been built yet.
class ComingSoon extends StatelessWidget {
  final String title;
  final String message;

  const ComingSoon({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SunMark(size: 56),
              const SizedBox(height: 16),
              Text(title, style: AppType.display),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppType.bodyMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
