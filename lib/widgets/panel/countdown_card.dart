import 'package:flutter/material.dart';
import '../../content/words.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';

/// The countdown to the next time they meet: his words for it, and the days
/// left as a big number ("Today" on the day itself).
class CountdownCard extends StatelessWidget {
  /// His words for it, or empty for the usual ones.
  final String label;
  final int days;

  const CountdownCard({super.key, required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppShape.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.isEmpty ? Words.countdownDefaultLabel : label,
              style: AppType.goldLabel,
            ),
            const SizedBox(height: 4),
            if (days == 0)
              Text(Words.countdownToday, style: AppType.display)
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$days', style: AppType.display),
                  const SizedBox(width: 8),
                  Text(Words.countdownUnit(days), style: AppType.bodyMuted),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
