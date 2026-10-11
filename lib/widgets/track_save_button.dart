import 'package:flutter/material.dart';

import '../models/track.dart';
import '../models/youtube_result.dart';
import 'save_button.dart';

/// The save button for any song. A YouTube song gets the real button (save,
/// saving, saved, try again); a local song is already a file, so it gets
/// nothing, and takes no room.
class TrackSaveButton extends StatelessWidget {
  final Track track;
  final double iconSize;
  final double boxSize;

  const TrackSaveButton({
    super.key,
    required this.track,
    this.iconSize = 22,
    this.boxSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final song = YoutubeResult.fromTrack(track);
    if (song == null) return const SizedBox.shrink();
    return SaveButton(song: song, iconSize: iconSize, boxSize: boxSize);
  }
}
