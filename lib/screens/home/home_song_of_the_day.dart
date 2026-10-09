import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/song_of_the_day.dart';
import '../../models/track.dart';
import '../../services/content_service.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../widgets/song_of_the_day_card.dart';

/// Home's song of the day, or nothing at all when he hasn't picked one or
/// the library doesn't have it. Brings its own gap above, so when it is
/// hidden Home looks exactly as it did before.
class HomeSongOfTheDay extends StatelessWidget {
  const HomeSongOfTheDay({super.key});

  @override
  Widget build(BuildContext context) {
    final pick =
        context.select<ContentService, SongOfTheDay?>((c) => c.songOfTheDay);
    if (pick == null) return const SizedBox.shrink();

    final library =
        context.select<LibraryService, List<Track>>((l) => l.tracks);
    final track = pick.resolve(library);
    if (track == null) return const SizedBox.shrink();

    // Only the playing song and whether it plays matter here, so position
    // ticks don't rebuild the card.
    return Selector<PlayerService, (String?, bool)>(
      selector: (_, player) => (player.current?.id, player.isPlaying),
      builder: (context, state, _) {
        final (currentId, playing) = state;
        final isCurrent = currentId == track.id;

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: SongOfTheDayCard(
            track: track,
            label: pick.label ?? Words.songOfTheDayLabel,
            note: pick.note,
            isPlaying: isCurrent && playing,
            // Already the song in the player: the card pauses and resumes it
            // instead of starting it over.
            onTap: () {
              final player = context.read<PlayerService>();
              if (isCurrent) {
                player.togglePlayPause();
              } else {
                player.playQueue([track]);
              }
            },
          ),
        );
      },
    );
  }
}
