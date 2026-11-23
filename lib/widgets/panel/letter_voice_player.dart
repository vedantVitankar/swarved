import 'package:flutter/material.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../services/letter_voice_controller.dart';
import '../../theme/colors.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../utils/duration_format.dart';
import '../compact_icon_button.dart';

/// A letter's recording: a play button, its own slider and its own times.
/// All of it is driven by [controller], never by the music player, so the
/// song's controls and slider are not involved.
///
/// Like the song's slider, dragging only moves the thumb and the elapsed
/// time; the recording is asked to seek once, when the finger lifts.
class LetterVoicePlayer extends StatefulWidget {
  final LetterVoiceController controller;

  const LetterVoicePlayer({super.key, required this.controller});

  @override
  State<LetterVoicePlayer> createState() => _LetterVoicePlayerState();
}

class _LetterVoicePlayerState extends State<LetterVoicePlayer> {
  /// Where the thumb is while she drags, and while the seek she let go on is
  /// still finishing. Null means follow the recording.
  double? _heldMs;

  Future<void> _release(double ms) async {
    setState(() => _heldMs = ms);
    try {
      await widget.controller.seek(Duration(milliseconds: ms.round()));
    } finally {
      if (mounted) setState(() => _heldMs = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final voice = widget.controller;
        final maxMs =
            voice.duration.inMilliseconds.toDouble().clamp(1, double.infinity);
        final shownMs = (_heldMs ?? voice.position.inMilliseconds.toDouble())
            .clamp(0, maxMs);
        final shown = Duration(milliseconds: shownMs.round());

        final String? problem = switch (voice.phase) {
          LetterVoicePhase.missing => Words.letterVoiceMissing,
          LetterVoicePhase.failed => Words.letterVoiceFailed,
          _ => null,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Words.letterPlayVoice, style: AppType.goldLabel),
            const SizedBox(height: 6),
            Row(
              children: [
                CompactIconButton(
                  icon: voice.isPlaying ? SwarGlyph.pause : SwarGlyph.play,
                  tooltip: voice.isPlaying ? Labels.pause : Labels.play,
                  boxSize: 44,
                  iconSize: 24,
                  color: AppColors.base,
                  background: AppColors.textPrimary,
                  busy: voice.isLoading,
                  onPressed: voice.isLoading ? null : voice.toggle,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: maxMs.toDouble(),
                    value: shownMs.toDouble(),
                    // Nothing to move until the recording has been opened.
                    onChanged: voice.canSeek
                        ? (v) => setState(() => _heldMs = v)
                        : null,
                    onChangeEnd: voice.canSeek ? _release : null,
                  ),
                ),
              ],
            ),
            Padding(
              // Lines the times up with the slider, past the button.
              padding: const EdgeInsets.only(left: 52 + 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(shown), style: AppType.readout),
                  Text(formatDuration(voice.duration), style: AppType.readout),
                ],
              ),
            ),
            if (problem != null) ...[
              const SizedBox(height: 6),
              Text(
                problem,
                style: AppType.bodyMuted.copyWith(color: AppColors.danger),
              ),
            ],
          ],
        );
      },
    );
  }
}
