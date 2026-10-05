import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../models/track.dart';
import '../screens/now_playing_screen.dart';
import '../services/player_service.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import 'compact_icon_button.dart';
import 'heart_button.dart';
import 'play_pause_button.dart';
import 'playback_mode_buttons.dart';
import 'seek_bar.dart';
import 'track_artwork.dart';
import 'volume_control.dart';

/// The wide-window mini player, after Spotify's desktop bar: the song on the
/// left, the controls with the seek bar in the centre, and the volume on
/// the right (added in the next step).
///
/// Every zone shrink-wraps its height. That matters: this sits in a
/// Scaffold's bottomNavigationBar on folder pages, where anything that
/// expands vertically (Center, Spacer) would stretch the card to full height.
class MiniPlayerDesktop extends StatelessWidget {
  final Track track;

  const MiniPlayerDesktop({super.key, required this.track});

  static const double _zoneGap = 16;
  static const double _controlsMaxWidth = 520;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _SongZone(track: track)),
          const SizedBox(width: _zoneGap),
          const Expanded(flex: 4, child: _ControlsZone()),
          const SizedBox(width: _zoneGap),
          // Right zone: volume, right-aligned so it mirrors the song zone.
          const Expanded(flex: 3, child: _VolumeZone()),
        ],
      ),
    );
  }
}

/// Artwork, title and artist (tap to open Now Playing), then the heart,
/// which sits outside the tap area so it never opens anything.
class _SongZone extends StatelessWidget {
  final Track track;

  const _SongZone({required this.track});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppShape.tile),
            onTap: () => NowPlayingScreen.open(context),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  TrackArtwork(
                    bytes: track.artworkBytes,
                    size: 56,
                    iconSize: 22,
                    radius: AppShape.thumbnail,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(track.title,
                            style: AppType.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(track.artist,
                            style: AppType.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const HeartButton(),
      ],
    );
  }
}

/// Shuffle, previous, play, next and repeat, with the seek bar underneath.
class _ControlsZone extends StatelessWidget {
  const _ControlsZone();

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerService>();

    // Align with heightFactor, not Center: it centres sideways but keeps
    // the height snug (see the class note above).
    return Align(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: MiniPlayerDesktop._controlsMaxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShuffleButton(),
                CompactIconButton(
                  icon: Icons.skip_previous,
                  tooltip: Labels.previousSong,
                  onPressed: player.restartOrPrevious,
                ),
                const PlayPauseButton.disc(size: 40),
                CompactIconButton(
                  icon: Icons.skip_next,
                  tooltip: Labels.nextSong,
                  onPressed: player.next,
                ),
                const RepeatButton(),
              ],
            ),
            const SizedBox(height: 2),
            const SeekBar(inline: true),
          ],
        ),
      ),
    );
  }
}

/// Volume icon and slider, right-aligned so the zone mirrors the song zone.
/// Align + heightFactor keeps the zone height snug — same pattern as
/// _ControlsZone above.
class _VolumeZone extends StatelessWidget {
  const _VolumeZone();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerRight,
      heightFactor: 1,
      child: VolumeControl(),
    );
  }
}
