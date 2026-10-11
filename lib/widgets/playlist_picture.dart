import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';
import '../utils/playlist_resolve.dart';
import 'playlist_art.dart';

/// A playlist's picture, kept up to date: it looks the playlist up by id and
/// gathers the pictures of its first songs, so Home, Library and the
/// playlist's own page all show the same cover.
class PlaylistPicture extends StatelessWidget {
  final String playlistId;
  final double size;
  final double radius;

  const PlaylistPicture({
    super.key,
    required this.playlistId,
    this.size = 46,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final playlist = context.select<PlaylistService, Playlist?>(
      (service) => service.byId(playlistId),
    );
    if (playlist == null) {
      return PlaylistArt(seed: playlistId, size: size, radius: radius);
    }

    final library =
        context.select<LibraryService, List<Track>>((l) => l.tracks);

    return PlaylistArt(
      seed: playlist.id,
      isLiked: playlist.isLiked,
      // Liked songs keeps its heart, so it never looks for pictures.
      covers: playlist.isLiked ? const [] : playlistCovers(playlist, library),
      size: size,
      radius: radius,
    );
  }
}
