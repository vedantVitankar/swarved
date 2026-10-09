import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/reveal_pieces.dart';

void main() {
  group('revealPieces', () {
    test('letters are one piece each', () {
      expect(revealPieces('Ved', letters: true), ['V', 'e', 'd']);
    });

    test('words keep the space after them, and join back to the text', () {
      const text = 'I made this,  for you.\nSlowly.';
      final pieces = revealPieces(text, letters: false);

      expect(pieces.first, 'I ');
      expect(pieces, hasLength(6));
      expect(pieces.join(), text);
    });

    test('empty text has no pieces', () {
      expect(revealPieces('', letters: true), isEmpty);
      expect(revealPieces('', letters: false), isEmpty);
    });
  });

  group('pieceAlpha', () {
    const count = 6;

    test('nothing shows at the start and everything at the end', () {
      for (var i = 0; i < count; i++) {
        expect(pieceAlpha(i, count, 0), 0);
        expect(pieceAlpha(i, count, 1), closeTo(1, 1e-9));
      }
    });

    test('pieces appear in order: an earlier piece is never fainter', () {
      for (var step = 0; step <= 20; step++) {
        final progress = step / 20;
        for (var i = 0; i < count - 1; i++) {
          expect(
            pieceAlpha(i, count, progress),
            greaterThanOrEqualTo(pieceAlpha(i + 1, count, progress)),
          );
        }
      }
    });

    test('the first piece is up before the last one has started', () {
      expect(pieceAlpha(0, count, 0.3), closeTo(1, 1e-9));
      expect(pieceAlpha(count - 1, count, 0.3), 0);
    });

    test('a single piece simply fades in with the progress', () {
      expect(pieceAlpha(0, 1, 0), 0);
      expect(pieceAlpha(0, 1, 0.4), closeTo(0.4, 1e-9));
      expect(pieceAlpha(0, 1, 1), 1);
    });

    test('no pieces does not break', () {
      expect(pieceAlpha(0, 0, 0.5), closeTo(0.5, 1e-9));
    });
  });
}
