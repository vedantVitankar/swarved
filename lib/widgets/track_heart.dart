import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../content/words.dart';
import '../models/track.dart';
import '../services/playlist_service.dart';
import 'heart_button.dart';
import 'playlist_picker.dart';

/// The heart for one song, on the mini player and Now Playing. It is filled
/// when the song is in Liked songs. A tap opens the playlist popup; holding
/// it adds or removes the song from Liked songs straight away.
class TrackHeart extends StatelessWidget {
  final Track track;
  final double iconSize;
  final double boxSize;

  const TrackHeart({
    super.key,
    required this.track,
    this.iconSize = 22,
    this.boxSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<PlaylistService, bool>(
      selector: (_, playlists) => playlists.isLiked(track),
      builder: (context, liked, _) => HeartButton(
        isFilled: liked,
        iconSize: iconSize,
        boxSize: boxSize,
        onPressed: () =>
            showPlaylistPicker(context, track, context.read<PlaylistService>()),
        onLongPress: () => quickToggle(context, track),
      ),
    );
  }

  /// Adds the song to Liked songs, or takes it out, straight away, and says
  /// which. Used by the heart's long press and by holding a song in a list.
  static void quickToggle(BuildContext context, Track track) {
    final nowLiked = context.read<PlaylistService>().toggleLiked(track);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nowLiked ? Words.likedAdded : Words.likedRemoved)),
    );
  }
}
