import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/track_tile.dart';
import '../widgets/mini_player_bar.dart';

class LibraryScreen extends StatelessWidget {
  final String title;
  final List<Track> tracks;

  const LibraryScreen({super.key, required this.title, required this.tracks});

  @override
  Widget build(BuildContext context) {
    // playQueue is a method call, not something this screen displays —
    // read() instead of watch() so this doesn't rebuild on its own.
    final player = context.read<PlayerService>();

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        title: Text(title.toUpperCase(), style: AppType.sectionLabel),
      ),
      // Only rebuilds the list when the active track's path actually
      // changes — not on every position tick. This is what stops the
      // folder view's artwork from disappearing during playback.
      bottomNavigationBar: const MiniPlayerBar(padBottom: true),
      body: Selector<PlayerService, String?>(
        selector: (_, player) => player.current?.filePath,
        builder: (context, activeFilePath, _) {
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return TrackTile(
                track: track,
                isActive: activeFilePath == track.filePath,
                onTap: () => player.playQueue(tracks, startIndex: index),
              );
            },
          );
        },
      ),
    );
  }
}
