import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/letter.dart';
import '../../services/letter_service.dart';
import '../../services/letter_voice_controller.dart';
import '../../services/media_cache.dart';
import '../../services/player_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../server_photo.dart';
import '../sun_mark.dart';
import 'letter_voice_player.dart';

/// Opens [letter], and notes that she did.
Future<void> showLetter(BuildContext context, Letter letter) {
  unawaited(context.read<LetterService>().markOpened(letter.id));
  return showDialog<void>(
    context: context,
    builder: (_) => LetterDialog(letter: letter),
  );
}

/// A letter, read in full: its heading, photo, words in his handwriting and
/// a player for his recording.
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
                LetterVoiceSection(letter: letter, file: voice),
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

/// A letter's recording, played on its own: its own button, slider and
/// times. Starting it pauses the music, and the music stays paused when the
/// recording ends or the letter is closed. It is never counted as listening,
/// and the song queue is not touched.
class LetterVoiceSection extends StatefulWidget {
  final Letter letter;

  /// The recording's name on the server.
  final String file;

  const LetterVoiceSection({
    super.key,
    required this.letter,
    required this.file,
  });

  @override
  State<LetterVoiceSection> createState() => _LetterVoiceSectionState();
}

class _LetterVoiceSectionState extends State<LetterVoiceSection> {
  late final LetterVoiceController _voice;

  @override
  void initState() {
    super.initState();
    _voice = LetterVoiceController(
      engine: context.read<PlayerService>(),
      fetch: context.read<MediaCache>().fileFor,
      file: widget.file,
      title: widget.letter.heading,
      artist: Words.voiceBreakFrom,
    );
  }

  /// Closing the letter closes this, which stops the recording.
  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LetterVoicePlayer(controller: _voice);
}
