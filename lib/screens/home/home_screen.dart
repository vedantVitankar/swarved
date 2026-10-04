import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/track.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../services/stats_service.dart';
import '../../theme/typography.dart';
import '../library_screen.dart';
import 'continue_card.dart';
import 'empty_library_state.dart';
import 'folder_ledger.dart';
import 'logbook_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final stats = context.watch<StatsService>();
    // player.playQueue is a method call in a button callback — this
    // screen never displays player state, so read() instead of watch()
    // stops it rebuilding (and re-decoding the ContinueCard artwork) on
    // every position tick during playback.
    final player = context.read<PlayerService>();

    if (library.rootPath == null) {
      return EmptyLibraryState(
        problem: library.problem,
        onChoose: library.pickAndScanFolder,
        onOpenSettings: library.openPermissionSettings,
      );
    }

    final recent = stats.recentUnique;
    final continueTrack = recent.isNotEmpty
        ? library.tracks.cast<Track?>().firstWhere(
              (t) => t?.filePath == recent.first.trackPath,
              orElse: () => null,
            )
        : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SWARVED', style: AppType.display),
                Text('${library.tracks.length} tracks', style: AppType.readout),
              ],
            ),
            const SizedBox(height: 28),
            if (continueTrack != null) ...[
              ContinueCard(
                track: continueTrack,
                onPlay: () => player.playQueue(
                  library.tracks,
                  startIndex: library.tracks.indexOf(continueTrack),
                ),
              ),
              const SizedBox(height: 28),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: FolderLedger(
                    byFolder: library.byFolder,
                    onOpenFolder: (folder, tracks) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            LibraryScreen(title: folder, tracks: tracks),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: LogbookCard(stats: stats)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
