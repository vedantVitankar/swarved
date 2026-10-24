import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/words.dart';
import '../models/memory.dart';
import '../services/content_service.dart';
import '../services/stats_service.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import '../utils/on_this_day.dart';

/// "On this day": a memory or a song from this date in an earlier year.
/// Nothing at all when there is none, and then it takes no room either.
class OnThisDayCard extends StatelessWidget {
  /// Today, for tests. Normally the real date.
  final DateTime? today;

  const OnThisDayCard({super.key, this.today});

  @override
  Widget build(BuildContext context) {
    final memories =
        context.select<ContentService, List<Memory>>((c) => c.memories);
    final entries = context.watch<StatsService>().entries;

    final day = pickOnThisDay(
      today ?? DateTime.now(),
      memories: memories,
      entries: entries,
    );
    if (day == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: OnThisDayView(day: day),
    );
  }
}

/// What [OnThisDayCard] shows once there is something to show.
class OnThisDayView extends StatelessWidget {
  final OnThisDay day;

  const OnThisDayView({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final memory = day.memory;
    final entry = day.entry;

    return Container(
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
          Text(Words.onThisDayLabel, style: AppType.goldLabel),
          const SizedBox(height: 2),
          Text(Words.onThisDayWhen(day.yearsAgo), style: AppType.bodyMuted),
          const SizedBox(height: 6),
          if (memory != null)
            Text(
              memory.caption,
              style: AppType.note.copyWith(color: AppColors.textPrimary),
            )
          else if (entry != null)
            Text(
              Words.onThisDaySong(entry.title, entry.artist),
              style: AppType.body,
            ),
        ],
      ),
    );
  }
}
