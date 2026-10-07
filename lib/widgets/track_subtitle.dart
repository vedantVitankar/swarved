import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/playback_words.dart';
import '../models/playback_problem.dart';
import '../models/track.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';

/// The artist's name under a song's title, which turns into a short message
/// in place when the song can't play. Shared by both mini players and Now
/// Playing, so a problem is told the same way everywhere.
class TrackSubtitle extends StatelessWidget {
  final Track track;
  final TextStyle style;
  final TextAlign? textAlign;

  const TrackSubtitle({
    super.key,
    required this.track,
    required this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, PlaybackProblem?>(
      selector: (_, player) => player.problem,
      builder: (context, problem, _) {
        return Text(
          problem == null ? track.artist : PlaybackWords.forProblem(problem),
          style:
              problem == null ? style : style.copyWith(color: AppColors.danger),
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
