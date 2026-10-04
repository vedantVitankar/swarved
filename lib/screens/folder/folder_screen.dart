import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/player_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/mini_player_bar.dart';
import '../../widgets/track_tile.dart';

/// One folder's songs. Opened from a Home tile or a Library row.
class FolderScreen extends StatelessWidget {
  final String title;
  final List<Track> tracks;

  const FolderScreen({super.key, required this.title, required this.tracks});

  /// The one way to open a folder, so Home and Library behave the same.
  static void open(
    BuildContext context, {
    required String title,
    required List<Track> tracks,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FolderScreen(title: title, tracks: tracks),
    ));
  }

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
      bottomNavigationBar: const MiniPlayerBar(padBottom: true),
      // Only rebuilds the list when the active track's path actually
      // changes — not on every position tick. This is what stops the
      // folder view's artwork from disappearing during playback.
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
