import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/words.dart';
import '../../models/letter.dart';
import '../../services/letter_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../utils/date_label.dart';
import 'letter_dialog.dart';

/// The "open when" letters: a title, then one row for each. A letter that is
/// not due yet shows its day and cannot be opened.
class LettersSection extends StatelessWidget {
  /// His own title, or empty for the usual one.
  final String title;
  final List<Letter> letters;

  const LettersSection({super.key, required this.title, required this.letters});

  @override
  Widget build(BuildContext context) {
    final opened = context.watch<LetterService>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? Words.lettersTitle : title,
            style: AppType.sectionLabel,
          ),
          const SizedBox(height: 10),
          for (final letter in letters) ...[
            LetterTile(
              letter: letter,
              opened: opened.isOpened(letter.id),
              onTap: letter.locked ? null : () => showLetter(context, letter),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// One letter's row. Only what is needed to draw it, so it can be tested on
/// its own.
class LetterTile extends StatelessWidget {
  final Letter letter;
  final bool opened;

  /// Null for a letter that cannot be opened yet.
  final VoidCallback? onTap;

  const LetterTile({
    super.key,
    required this.letter,
    required this.opened,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocksOn = letter.unlocksOn;
    final String? note = letter.locked
        ? (unlocksOn == null ? null : Words.letterOpensOn(longDate(unlocksOn)))
        : (opened ? null : Words.letterNew);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppShape.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppShape.card),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppShape.card),
          ),
          child: Row(
            children: [
              Icon(
                letter.locked
                    ? Icons.lock_outline_rounded
                    : (opened
                        ? Icons.drafts_outlined
                        : Icons.mail_outline_rounded),
                size: 20,
                color: letter.locked ? AppColors.textFaint : AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.heading,
                      style: letter.locked
                          ? AppType.bodyMuted
                          : AppType.body,
                    ),
                    if (note != null)
                      Text(
                        note,
                        style: AppType.goldLabel,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
