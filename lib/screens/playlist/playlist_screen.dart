import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/play_source.dart';
import '../../models/playlist.dart';
import '../../services/library_service.dart';
import '../../services/player_service.dart';
import '../../services/playlist_service.dart';
import '../../theme/colors.dart';
import '../../theme/responsive.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../utils/playlist_play.dart';
import '../../utils/playlist_resolve.dart';
import '../../widgets/mini_player_bar.dart';
import '../../widgets/playlist_item_row.dart';
import '../../widgets/swar_icon.dart';
import 'playlist_header.dart';

/// One playlist's page: its songs in order, Play and Shuffle, and for her own
/// playlists (and Liked songs) holding a song to move it and swiping it away
/// to take it out. Opened from a Home tile or a Library row.
class PlaylistScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  /// The one way to open a playlist, so Home and Library behave the same.
  static void open(BuildContext context, String playlistId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlaylistScreen(playlistId: playlistId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PlaylistService>();
    final library = context.watch<LibraryService>();
    final playlist = service.byId(playlistId);

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
          constraints: const BoxConstraints(
            maxWidth: Responsive.contentMaxWidth,
          ),
          child: playlist == null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(Words.playlistGone, style: AppType.bodyMuted),
                )
              : _PlaylistBody(
                  playlist: playlist,
                  lines: resolvePlaylist(playlist, library.tracks),
                ),
        ),
      ),
    );
  }
}

class _PlaylistBody extends StatelessWidget {
  final Playlist playlist;
  final List<ResolvedItem> lines;

  const _PlaylistBody({required this.playlist, required this.lines});

  @override
  Widget build(BuildContext context) {
    // Only methods are called on these, so this page does not rebuild with
    // every position tick.
    final player = context.read<PlayerService>();
    final service = context.read<PlaylistService>();
    final playable = playableTracks(lines);
    final source = PlaySource(playlist.name);

    final header = PlaylistHeader(
      playlist: playlist,
      canPlay: playable.isNotEmpty,
      onPlay: () => player.playQueue(playable, source: source),
      onShuffle: () => player.playShuffled(playable, source: source),
    );

    if (lines.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          header,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(Words.playlistEmpty, style: AppType.bodyMuted),
          ),
        ],
      );
    }

    Widget row(BuildContext context, int i, String? activeId) {
      final line = lines[i];
      return PlaylistItemRow(
        item: line.item,
        track: line.track,
        isActive: line.track != null && line.track!.id == activeId,
        onTap: () {
          final start = playableIndexOf(lines, i);
          if (start == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(Words.songNotOnDevice)),
            );
            return;
          }
          player.playQueue(playable, startIndex: start, source: source);
        },
      );
    }

    // Only the playing song's id matters here, so position ticks don't
    // rebuild the list.
    return Selector<PlayerService, String?>(
      selector: (_, p) => p.current?.id,
      builder: (context, activeId, _) {
        if (!playlist.isEditable) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: lines.length + 1,
            itemBuilder: (context, i) =>
                i == 0 ? header : row(context, i - 1, activeId),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          header: header,
          itemCount: lines.length,
          // Hold a row to drag it, on touch screens and with a mouse alike.
          buildDefaultDragHandles: false,
          onReorder: (from, to) {
            // Dragging down reports its target one place too high.
            service.move(playlist.id, from, to > from ? to - 1 : to);
          },
          itemBuilder: (context, i) {
            final key = lines[i].item.key;
            return ReorderableDelayedDragStartListener(
              key: ValueKey(key),
              index: i,
              child: Dismissible(
                key: ValueKey('dismiss:$key'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.surfaceRaised,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const SwarIcon(
                    glyph: SwarGlyph.close,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                onDismissed: (_) {
                  service.remove(playlist.id, key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Words.songTakenOut(playlist.name)),
                    ),
                  );
                },
                child: row(context, i, activeId),
              ),
            );
          },
        );
      },
    );
  }
}
