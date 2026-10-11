import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/typography.dart';
import 'track_heart.dart';
import 'track_save_button.dart';

/// The end of a song's row in any list: download, length, heart. Download
/// only shows for YouTube songs. In a list that mixes local and YouTube
/// songs, [keepSaveSlot] leaves the download's room empty for a local song,
/// so every length lines up.
class SongRowEnd extends StatelessWidget {
  /// The song to save and like. Null draws the length alone, for a song that
  /// is not on this device and so cannot be liked from here.
  final Track? track;
  final String durationLabel;
  final bool keepSaveSlot;

  const SongRowEnd({
    super.key,
    required this.track,
    required this.durationLabel,
    this.keepSaveSlot = false,
  });

  static const double box = 36;
  static const double icon = 20;

  @override
  Widget build(BuildContext context) {
    final track = this.track;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (track != null && !track.isLocal)
          TrackSaveButton(track: track, iconSize: icon, boxSize: box)
        else if (keepSaveSlot)
          const SizedBox(width: box),
        Text(durationLabel, style: AppType.readout),
        if (track != null)
          TrackHeart(track: track, iconSize: icon, boxSize: box)
        else
          const SizedBox(width: 12),
      ],
    );
  }
}
