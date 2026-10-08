import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/recap.dart';
import '../../services/content_service.dart';
import '../../services/stats_service.dart';
import '../../theme/colors.dart';
import '../../theme/responsive.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../utils/date_label.dart';
import '../../utils/duration_format.dart';
import '../../widgets/mini_player_bar.dart';
import '../../widgets/swar_icon.dart';

/// The year in songs, read from the logbook, ending with his own line.
class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<StatsService>().entries;
    final recap = Recap.from(entries);
    final line = context.select<ContentService, String?>(
            (c) => c.recapSettings.line) ??
        Words.recapClosing;

    final stats = <_Stat>[
      if (recap != null) ...[
        if (recap.topSong != null)
          _Stat(
            Words.recapTopSong,
            recap.topSong!.title,
            _songDetail(recap.topSong!),
          ),
        if (recap.topArtist != null)
          _Stat(Words.recapTopArtist, recap.topArtist!, null),
        _Stat(Words.recapTotal, listenedLabel(recap.totalListened), null),
        if (recap.busiestDay != null)
          _Stat(
            Words.recapBusiestDay,
            longDate(recap.busiestDay!),
            listenedLabel(recap.busiestDayListened),
          ),
        if (recap.lateNightSong != null)
          _Stat(
            Words.recapLateNight,
            recap.lateNightSong!.title,
            recap.lateNightSong!.artist.isEmpty
                ? null
                : recap.lateNightSong!.artist,
          ),
      ],
    ];

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const SwarIcon(
            glyph: SwarGlyph.back,
            size: 24,
            color: AppColors.textPrimary,
          ),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottomNavigationBar: const MiniPlayerBar(padBottom: true),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Text(Words.recapTitle, style: AppType.display),
              const SizedBox(height: 20),
              for (final stat in stats) stat,
              const SizedBox(height: 8),
              Text(
                line,
                style: AppType.note.copyWith(
                  fontSize: 26,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Arijit Singh · played 12 times", or just the plays when no artist.
String _songDetail(RecapSong song) {
  final plays = Words.recapPlays(song.plays);
  return song.artist.isEmpty ? plays : '${song.artist} · $plays';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;

  const _Stat(this.label, this.value, this.detail);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.goldLabel),
          const SizedBox(height: 4),
          Text(value, style: AppType.trackTitle.copyWith(fontSize: 24)),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(detail!, style: AppType.bodyMuted),
          ],
        ],
      ),
    );
  }
}
