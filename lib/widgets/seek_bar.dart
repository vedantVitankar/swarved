import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/typography.dart';
import '../utils/duration_format.dart';

/// The song's slider with its elapsed and total time. Shared by Now Playing
/// (times under the slider) and the desktop mini player (times beside it).
///
/// Dragging only moves the thumb and the elapsed time. The player is asked
/// to seek once, when the finger lifts, so a YouTube song sends one range
/// request instead of one for every tick of the drag.
///
/// Isolated so ONLY this widget rebuilds on every position tick — nothing
/// around it gets pulled into that.
class SeekBar extends StatefulWidget {
  /// Puts the times either side of the slider instead of underneath it.
  final bool inline;

  const SeekBar({super.key, this.inline = false});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  static const double _timeWidth = 48;

  /// Where the thumb is while the listener drags, and while the seek they
  /// let go on is still finishing. Null means follow the player.
  double? _heldMs;

  Future<void> _release(PlayerService player, double ms) async {
    setState(() => _heldMs = ms);
    try {
      await player.seek(Duration(milliseconds: ms.round()));
    } finally {
      if (mounted) setState(() => _heldMs = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, (Duration, Duration)>(
      selector: (_, player) => (player.position, player.duration),
      builder: (context, data, _) {
        final (playerPos, dur) = data;
        final player = context.read<PlayerService>();
        final maxMs = dur.inMilliseconds.toDouble().clamp(1, double.infinity);
        final shownMs =
            (_heldMs ?? playerPos.inMilliseconds.toDouble()).clamp(0, maxMs);
        final shown = Duration(milliseconds: shownMs.round());

        final slider = Slider(
          min: 0,
          max: maxMs.toDouble(),
          value: shownMs.toDouble(),
          // Nothing to seek in until the player knows the song's length.
          onChanged:
              dur == Duration.zero ? null : (v) => setState(() => _heldMs = v),
          onChangeEnd: dur == Duration.zero ? null : (v) => _release(player, v),
        );

        if (widget.inline) {
          return Row(
            children: [
              SizedBox(
                width: _timeWidth,
                child: Text(
                  formatDuration(shown),
                  style: AppType.readout,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(child: slider),
              SizedBox(
                width: _timeWidth,
                child: Text(formatDuration(dur), style: AppType.readout),
              ),
            ],
          );
        }

        return Column(
          children: [
            slider,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(shown), style: AppType.readout),
                  Text(formatDuration(dur), style: AppType.readout),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
