import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song_of_the_day.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

/// The song from the day of a photo note: its name and a button to play it.
/// Nothing when it is one of her own songs that is not on this device.
class PhotoNoteSong extends StatelessWidget {
  final SongOfTheDay song;

  const PhotoNoteSong({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final library =
        context.select<LibraryService, List<Track>>((l) => l.tracks);
    final track = song.resolve(library);
    if (track == null) return const SizedBox.shrink();

    return Selector<PlayerService, (String?, bool)>(
      selector: (_, player) => (player.current?.id, player.isPlaying),
      builder: (context, state, _) {
        final (currentId, playing) = state;
        final isCurrent = currentId == track.id;
        final showPause = isCurrent && playing;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final player = context.read<PlayerService>();
              if (isCurrent) {
                player.togglePlayPause();
              } else {
                player.playQueue([track]);
              }
            },
            child: Row(
              children: [
                Icon(
                  showPause
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    track.artist.isEmpty
                        ? track.title
                        : '${track.title} · ${track.artist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
