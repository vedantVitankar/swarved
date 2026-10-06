import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../models/track.dart';
import '../../services/player_service.dart';
import '../../theme/colors.dart';
import '../../theme/responsive.dart';
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
        // The title scrolls under the bar; no colour shift while it does.
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBar: const MiniPlayerBar(padBottom: true),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Responsive.contentMaxWidth,
          ),
          // Only rebuilds the list when the active track's path actually
          // changes — not on every position tick. This is what stops the
          // folder view's artwork from disappearing during playback.
          child: Selector<PlayerService, String?>(
            selector: (_, player) => player.current?.id,
            builder: (context, activeId, _) {
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                // One extra item at the top for the title.
                itemCount: tracks.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _Header(title: title, songCount: tracks.length);
                  }
                  final index = i - 1;
                  final track = tracks[index];
                  return TrackTile(
                    track: track,
                    isActive: activeId == track.id,
                    onTap: () => player.playQueue(tracks, startIndex: index),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int songCount;

  const _Header({required this.title, required this.songCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.display),
          const SizedBox(height: 4),
          Text(Labels.songCount(songCount), style: AppType.caption),
        ],
      ),
    );
  }
}
