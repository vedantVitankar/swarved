import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../services/stats_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../widgets/mini_waveform.dart';

class LogbookCard extends StatelessWidget {
  final StatsService stats;
  const LogbookCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final topArtist = stats.topArtist;

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
          Text(Labels.logbook, style: AppType.sectionLabel),
          const SizedBox(height: 10),
          Text(Labels.minutesToday(stats.todayTotal.inMinutes),
              style: AppType.titleMedium),
          const SizedBox(height: 4),
          Text(
            topArtist != null ? Labels.mostPlayed(topArtist) : Words.noPlaysYet,
            style: AppType.bodyMuted,
          ),
          const SizedBox(height: 12),
          MiniWaveform(seed: '${stats.entries.length}-$topArtist'),
        ],
      ),
    );
  }
}
