import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/typography.dart';
import '../utils/duration_format.dart';

/// The song's slider with its elapsed and total time. Shared by Now Playing
/// (times under the slider) and the desktop mini player (times beside it).
///
/// Isolated so ONLY this widget rebuilds on every position tick — nothing
/// around it gets pulled into that.
class SeekBar extends StatelessWidget {
  /// Puts the times either side of the slider instead of underneath it.
  final bool inline;

  const SeekBar({super.key, this.inline = false});

  static const double _timeWidth = 48;

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, (Duration, Duration)>(
      selector: (_, player) => (player.position, player.duration),
      builder: (context, data, _) {
        final (pos, dur) = data;
        final player = context.read<PlayerService>();
        final slider = Slider(
          min: 0,
          max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
          value: pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble(),
          onChanged: (v) => player.seek(Duration(milliseconds: v.round())),
        );

        if (inline) {
          return Row(
            children: [
              SizedBox(
                width: _timeWidth,
                child: Text(
                  formatDuration(pos),
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
                  Text(formatDuration(pos), style: AppType.readout),
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
