import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/letter.dart';
import '../../models/track.dart';
import '../../services/letter_service.dart';
import '../../services/media_cache.dart';
import '../../services/player_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../server_photo.dart';
import '../sun_mark.dart';
import '../swar_outlined_button.dart';

/// Opens [letter], and notes that she did.
Future<void> showLetter(BuildContext context, Letter letter) {
  unawaited(context.read<LetterService>().markOpened(letter.id));
  return showDialog<void>(
    context: context,
    builder: (_) => LetterDialog(letter: letter),
  );
}

/// A letter, read in full: its heading, photo, words in his handwriting and
/// a button to hear his recording.
class LetterDialog extends StatelessWidget {
  final Letter letter;

  const LetterDialog({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final photo = letter.photo;
    final voice = letter.voice;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: const BorderSide(color: AppColors.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(letter.heading, style: AppType.goldLabel),
              if (letter.when.isNotEmpty && letter.title.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(letter.title, style: AppType.trackTitle),
              ],
              if (photo != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppShape.tile),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ServerPhoto(
                      name: photo,
                      cacheWidth: 960,
                      placeholder: const ColoredBox(
                        color: AppColors.base,
                        child: Center(child: SunMark(size: 64)),
                      ),
                    ),
                  ),
                ),
              ],
              if (letter.body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  letter.body,
                  style: AppType.note.copyWith(color: AppColors.textPrimary),
                ),
              ],
              if (voice != null) ...[
                const SizedBox(height: 14),
                LetterVoiceButton(letter: letter, file: voice),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(Words.letterClose, style: AppType.bodyMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plays a letter's recording through the player, like a song, so the usual
/// controls and the media keys work. It is never counted as listening.
class LetterVoiceButton extends StatefulWidget {
  final Letter letter;

  /// The recording's name on the server.
  final String file;

  const LetterVoiceButton({super.key, required this.letter, required this.file});

  @override
  State<LetterVoiceButton> createState() => _LetterVoiceButtonState();
}

class _LetterVoiceButtonState extends State<LetterVoiceButton> {
  bool _fetching = false;
  bool _missing = false;

  Future<void> _play() async {
    final cache = context.read<MediaCache>();
    final player = context.read<PlayerService>();
    setState(() {
      _fetching = true;
      _missing = false;
    });
    final file = await cache.fileFor(widget.file);
    if (!mounted) return;
    setState(() {
      _fetching = false;
      _missing = file == null;
    });
    if (file == null) return;
    await player.playQueue([
      Track(
        filePath: file.path,
        title: widget.letter.heading,
        artist: Words.voiceBreakFrom,
        album: '',
        duration: Duration.zero,
        folder: Track.letterRecordingFolder,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwarOutlinedButton(
          label: Words.letterPlayVoice,
          onPressed: _fetching ? null : _play,
        ),
        if (_missing) ...[
          const SizedBox(height: 6),
          Text(
            Words.letterVoiceMissing,
            style: AppType.bodyMuted.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}
