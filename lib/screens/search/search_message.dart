import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// A quiet line of text in the results, with an optional action beneath it.
/// Used for "nothing found", "server unreachable" and the like, so the
/// screen never turns noisy.
class SearchMessage extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SearchMessage({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final action = onAction;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppType.bodyMuted),
          if (label != null && action != null)
            TextButton(
              onPressed: action,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 36),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                label,
                style: AppType.bodyMuted.copyWith(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
