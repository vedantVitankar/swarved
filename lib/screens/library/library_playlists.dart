import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../services/playlist_service.dart';
import '../../theme/typography.dart';
import '../../widgets/playlist_row.dart';
import '../playlist/playlist_screen.dart';

/// The Playlists view in the Library: Liked songs first, then her playlists.
/// It needs no music folder, because a playlist can hold YouTube songs.
class LibraryPlaylists extends StatelessWidget {
  const LibraryPlaylists({super.key});

  @override
  Widget build(BuildContext context) {
    final playlists = context.watch<PlaylistService>().playlists;
    final onlyLiked = playlists.length <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final playlist in playlists)
          PlaylistRow(
            playlist: playlist,
            onTap: () => PlaylistScreen.open(context, playlist.id),
          ),
        if (onlyLiked)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(Words.playlistsHint, style: AppType.bodyMuted),
          ),
      ],
    );
  }
}
