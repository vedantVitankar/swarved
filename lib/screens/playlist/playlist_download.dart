import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/save_words.dart';
import '../../models/youtube_result.dart';
import '../../services/playlist_downloader.dart';
import '../../services/save_controller.dart';
import '../../theme/colors.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../widgets/compact_icon_button.dart';
import '../../widgets/save_folder_dialog.dart';

/// Saves a whole playlist into a folder of its own. Shows nothing when the
/// playlist has no YouTube songs. While it runs the button is a spinner that
/// stops the run when tapped; when every song is saved it shows the tick.
class PlaylistDownloadButton extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  final List<YoutubeResult> songs;

  const PlaylistDownloadButton({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.songs,
  });

  // A button with no handler would let the tap fall through.
  static void _absorbTap() {}

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();

    final downloader = context.watch<PlaylistDownloader>();
    final view = downloader.viewOf(playlistId);

    if (view != null) {
      return CompactIconButton(
        icon: SwarGlyph.download,
        busy: true,
        color: AppColors.accent,
        tooltip: SaveWords.stopDownloading,
        onPressed:
            view.stopping ? _absorbTap : () => downloader.cancel(playlistId),
      );
    }

    if (downloader.missingCount(songs) == 0) {
      return const CompactIconButton(
        icon: SwarGlyph.saved,
        color: AppColors.accent,
        tooltip: SaveWords.allDownloaded,
        onPressed: _absorbTap,
      );
    }

    return CompactIconButton(
      icon: SwarGlyph.download,
      color: AppColors.accent,
      tooltip: SaveWords.downloadAll,
      onPressed: () => _start(context),
    );
  }

  /// Starts the download and says how it ended. The messenger is taken before
  /// any wait, because the page may be gone by the time the last song lands.
  Future<void> _start(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saves = context.read<SaveController>();
    final downloader = context.read<PlaylistDownloader>();

    // The first save has nowhere to go yet: say why, then let her pick.
    if (saves.needsFolder) {
      final go = await showSaveFolderDialog(context);
      if (go != true) return;
    }

    final result = await downloader.download(
      playlistId: playlistId,
      playlistName: playlistName,
      songs: songs,
    );
    if (result == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(SaveWords.forBatch(result))),
    );
  }
}

/// A line under the playlist's buttons that says how far its download has
/// got. Takes no room when nothing is downloading.
class PlaylistDownloadStatus extends StatelessWidget {
  final String playlistId;

  const PlaylistDownloadStatus({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    final view = context.select<PlaylistDownloader, BatchView?>(
      (downloader) => downloader.viewOf(playlistId),
    );
    if (view == null) return const SizedBox.shrink();

    final text = view.stopping
        ? SaveWords.stoppingAfterThis
        : SaveWords.downloadingProgress(view.finished, view.total);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text, style: AppType.caption),
    );
  }
}
