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

  const TrackHeart({super.key, required this.track, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    final service = context.read<PlaylistService>();
    return Selector<PlaylistService, bool>(
      selector: (_, playlists) => playlists.isLiked(track),
      builder: (context, liked, _) => HeartButton(
        isFilled: liked,
        iconSize: iconSize,
        onPressed: () => showPlaylistPicker(context, track, service),
        onLongPress: () => _quickToggle(context, service),
      ),
    );
  }

  void _quickToggle(BuildContext context, PlaylistService service) {
    final nowLiked = service.toggleLiked(track);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(nowLiked ? Words.likedAdded : Words.likedRemoved)),
    );
  }
}
