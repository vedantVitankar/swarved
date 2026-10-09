import 'package:flutter/material.dart';
import '../../utils/reveal_pieces.dart';
import '../../utils/welcome_timeline.dart';

/// Text that appears piece by piece, each letter or word fading in after the
/// one before, while the letters settle closer together.
///
/// Every piece is its own small Text that fades with an Opacity, so the
/// words are laid out once and never shift while they appear. (Fading by
/// changing the colour of one big Text makes Flutter re-paint it without
/// re-measuring, which it asserts against in debug mode.) Screen readers get
/// the whole text in one go instead of piece by piece.
class RevealText extends StatelessWidget {
  final String text;

  /// The look of the finished text.
  final TextStyle style;

  /// The whole intro, 0 to 1.
  final Animation<double> progress;

  /// Where in the intro this text appears.
  final TimeSpan span;

  /// Letters one by one, or words one by one.
  final bool letters;

  /// Extra space between letters at the start, which settles to none.
  final double extraSpacing;

  const RevealText({
    super.key,
    required this.text,
    required this.style,
    required this.progress,
    required this.span,
    this.letters = false,
    this.extraSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = revealPieces(text, letters: letters);

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final p = span.at(progress.value);
          final settle = 1 - Curves.easeOutCubic.transform(p);
          final spacing = (style.letterSpacing ?? 0) + extraSpacing * settle;
          final pieceStyle = style.copyWith(letterSpacing: spacing);

          return Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < pieces.length; i++)
                Opacity(
                  opacity: pieceAlpha(i, pieces.length, p),
                  child: Text(pieces[i], style: pieceStyle),
                ),
            ],
          );
        },
      ),
    );
  }
}
