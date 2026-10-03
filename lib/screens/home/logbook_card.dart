import 'package:flutter/material.dart';
import '../../services/stats_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/mini_waveform.dart';

class LogbookCard extends StatelessWidget {
  final StatsService stats;
  const LogbookCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final todayMinutes = stats.todayTotal.inMinutes;
    final topArtist = stats.topArtist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LOGBOOK', style: AppType.sectionLabel),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$todayMinutes min today', style: AppType.titleMedium),
              const SizedBox(height: 4),
              Text(
                topArtist != null
                    ? 'Most played · $topArtist'
                    : 'No plays logged yet',
                style: AppType.bodyMuted,
              ),
              const SizedBox(height: 12),
              MiniWaveform(seed: '${stats.entries.length}-$topArtist'),
            ],
          ),
        ),
      ],
    );
  }
}
