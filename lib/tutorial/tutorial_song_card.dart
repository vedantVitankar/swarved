import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/words.dart';
import '../models/tutorial_song.dart';
import '../services/player_service.dart';
import '../widgets/song_of_the_day_card.dart';

/// Home's card while the tutorial runs: the tutorial's own song, in place of
/// the song of the day from the content file. Plays like the song of the
/// day does, and carries the key the spotlight lights up.
class TutorialSongCard extends StatelessWidget {
  final TutorialSong song;
  final GlobalKey cardKey;

  const TutorialSongCard(
      {super.key, required this.song, required this.cardKey});

  @override
  Widget build(BuildContext context) {
    final track = song.track;

    return Selector<PlayerService, (String?, bool)>(
      selector: (_, player) => (player.current?.id, player.isPlaying),
      builder: (context, state, _) {
        final (currentId, playing) = state;
        final isCurrent = currentId == track.id;

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: KeyedSubtree(
            key: cardKey,
            child: SongOfTheDayCard(
              track: track,
              label: song.label ?? Words.songOfTheDayLabel,
              note: song.note,
              isPlaying: isCurrent && playing,
              onTap: () {
                final player = context.read<PlayerService>();
                if (isCurrent) {
                  player.togglePlayPause();
                } else {
                  player.playQueue([track]);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
