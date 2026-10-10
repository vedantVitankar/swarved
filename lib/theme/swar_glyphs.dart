import 'dart:ui';

/// Every icon SwarVed draws. The first ten are the shapes from the theme
/// preview, on its 24 by 24 grid; the rest are drawn in the same style
/// (round line ends, 1.7 stroke) for places the preview doesn't show.
enum SwarGlyph {
  home,
  search,
  shelf, // the library tab
  heart,
  heartFilled,
  play,
  pause,
  previous,
  next,
  shuffle,
  repeat,
  repeatOne,
  down,
  back,
  close,
  saved,
  refresh,
  download,
  volumeOff,
  volumeLow,
  volumeHigh,
  disc, // stands in for missing artwork
  add, // a plus: make something new
  check, // a tick: chosen
}

/// What one glyph is made of: a solid part, a line part, or both.
class GlyphShape {
  final Path? fill;
  final Path? stroke;

  const GlyphShape({this.fill, this.stroke});
}

/// The shapes themselves. Each is built once, on first use, and reused.
class SwarGlyphs {
  SwarGlyphs._();

  static const double grid = 24;
  static const double strokeWidth = 1.7;

  static final Map<SwarGlyph, GlyphShape> _cache = {};

  static GlyphShape shapeOf(SwarGlyph glyph) =>
      _cache.putIfAbsent(glyph, () => _build(glyph));

  static GlyphShape _build(SwarGlyph glyph) => switch (glyph) {
        SwarGlyph.home => GlyphShape(stroke: _home()),
        SwarGlyph.search => GlyphShape(stroke: _search()),
        SwarGlyph.shelf => GlyphShape(stroke: _shelf()),
        SwarGlyph.heart => GlyphShape(stroke: _heart()),
        SwarGlyph.heartFilled => GlyphShape(fill: _heart(), stroke: _heart()),
        SwarGlyph.play => GlyphShape(fill: _play()),
        SwarGlyph.pause => GlyphShape(fill: _pause()),
        SwarGlyph.previous => GlyphShape(fill: _previous()),
        SwarGlyph.next => GlyphShape(fill: _next()),
        SwarGlyph.shuffle => GlyphShape(stroke: _shuffle()),
        SwarGlyph.repeat => GlyphShape(stroke: _repeat()),
        SwarGlyph.repeatOne => GlyphShape(stroke: _repeatOne()),
        SwarGlyph.down => GlyphShape(stroke: _down()),
        SwarGlyph.back => GlyphShape(stroke: _back()),
        SwarGlyph.close => GlyphShape(stroke: _close()),
        SwarGlyph.saved => GlyphShape(stroke: _saved()),
        SwarGlyph.refresh => GlyphShape(stroke: _refresh()),
        SwarGlyph.download => GlyphShape(stroke: _download()),
        SwarGlyph.volumeOff => GlyphShape(stroke: _volumeOff()),
        SwarGlyph.volumeLow => GlyphShape(stroke: _volumeLow()),
        SwarGlyph.volumeHigh => GlyphShape(stroke: _volumeHigh()),
        SwarGlyph.disc => GlyphShape(stroke: _disc()),
        SwarGlyph.add => GlyphShape(stroke: _add()),
        SwarGlyph.check => GlyphShape(stroke: _check()),
      };

  // ---- From the theme preview ----

  static Path _home() => Path()
    ..moveTo(3, 11)
    ..lineTo(12, 3)
    ..lineTo(21, 11)
    ..lineTo(21, 20)
    ..arcToPoint(const Offset(20, 21), radius: const Radius.circular(1))
    ..lineTo(15, 21)
    ..lineTo(15, 15)
    ..lineTo(9, 15)
    ..lineTo(9, 21)
    ..lineTo(4, 21)
    ..arcToPoint(const Offset(3, 20), radius: const Radius.circular(1))
    ..close();

  static Path _search() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(11, 11), radius: 7))
    ..moveTo(21, 21)
    ..lineTo(16.5, 16.5);

  static Path _shelf() => Path()
    ..moveTo(4, 4)
    ..lineTo(4, 20)
    ..moveTo(9, 4)
    ..lineTo(9, 20)
    ..moveTo(14, 6)
    ..lineTo(19, 20);

  static Path _heart() => Path()
    ..moveTo(12, 20)
    ..cubicTo(12, 20, 5, 15.5, 5, 10)
    ..arcToPoint(const Offset(12, 7.5), radius: const Radius.circular(4))
    ..arcToPoint(const Offset(19, 10), radius: const Radius.circular(4))
    ..cubicTo(19, 15.5, 12, 20, 12, 20)
    ..close();

  static Path _play() => Path()
    ..moveTo(7, 5)
    ..lineTo(19, 12)
    ..lineTo(7, 19)
    ..close();

  static Path _previous() => Path()
    ..moveTo(19, 5)
    ..lineTo(9, 12)
    ..lineTo(19, 19)
    ..close()
    ..addRRect(RRect.fromLTRBR(5, 5, 7, 19, const Radius.circular(1)));

  static Path _next() => Path()
    ..moveTo(5, 5)
    ..lineTo(15, 12)
    ..lineTo(5, 19)
    ..close()
    ..addRRect(RRect.fromLTRBR(17, 5, 19, 19, const Radius.circular(1)));

  static Path _shuffle() => Path()
    ..moveTo(3, 7)
    ..lineTo(7, 7)
    ..lineTo(17, 17)
    ..lineTo(21, 17)
    ..moveTo(3, 17)
    ..lineTo(7, 17)
    ..lineTo(10, 14)
    ..moveTo(14, 10)
    ..lineTo(17, 7)
    ..lineTo(21, 7)
    ..moveTo(18, 4)
    ..lineTo(21, 7)
    ..lineTo(18, 10)
    ..moveTo(18, 14)
    ..lineTo(21, 17)
    ..lineTo(18, 20);

  static Path _repeat() => Path()
    ..moveTo(17, 2)
    ..lineTo(21, 6)
    ..lineTo(17, 10)
    ..moveTo(3, 11)
    ..lineTo(3, 9)
    ..arcToPoint(const Offset(6, 6), radius: const Radius.circular(3))
    ..lineTo(21, 6)
    ..moveTo(7, 22)
    ..lineTo(3, 18)
    ..lineTo(7, 14)
    ..moveTo(21, 13)
    ..lineTo(21, 15)
    ..arcToPoint(const Offset(18, 18), radius: const Radius.circular(3))
    ..lineTo(3, 18);

  static Path _down() => Path()
    ..moveTo(6, 9)
    ..lineTo(12, 15)
    ..lineTo(18, 9);

  // ---- Same style, not in the preview ----

  /// Repeat with a small "1" in the middle.
  static Path _repeatOne() => _repeat()
    ..moveTo(11, 10.5)
    ..lineTo(12.5, 9.5)
    ..lineTo(12.5, 14.5);

  static Path _pause() => Path()
    ..addRRect(RRect.fromLTRBR(6.5, 5, 10, 19, const Radius.circular(1)))
    ..addRRect(RRect.fromLTRBR(14, 5, 17.5, 19, const Radius.circular(1)));

  static Path _back() => Path()
    ..moveTo(15, 6)
    ..lineTo(9, 12)
    ..lineTo(15, 18);

  static Path _close() => Path()
    ..moveTo(6, 6)
    ..lineTo(18, 18)
    ..moveTo(18, 6)
    ..lineTo(6, 18);

  static Path _add() => Path()
    ..moveTo(12, 5)
    ..lineTo(12, 19)
    ..moveTo(5, 12)
    ..lineTo(19, 12);

  static Path _check() => Path()
    ..moveTo(5, 12.5)
    ..lineTo(10, 17.5)
    ..lineTo(19, 7);

  /// A circle with a tick: a song that is already saved.
  static Path _saved() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8))
    ..moveTo(8, 12.2)
    ..lineTo(11, 15)
    ..lineTo(16, 9.2);

  /// A circular arrow: try again.
  static Path _refresh() => Path()
    ..moveTo(19.47, 14.64)
    ..arcToPoint(
      const Offset(17.61, 6.4),
      radius: const Radius.circular(7.92),
      largeArc: true,
    )
    ..lineTo(21.68, 10.24)
    ..moveTo(21.68, 4.96)
    ..lineTo(21.68, 10.24)
    ..lineTo(16.4, 10.24);

  static Path _download() => Path()
    ..moveTo(12, 4)
    ..lineTo(12, 15.5)
    ..moveTo(7, 10.5)
    ..lineTo(12, 15.5)
    ..lineTo(17, 10.5)
    ..moveTo(5, 19.5)
    ..lineTo(19, 19.5);

  static Path _speaker() => Path()
    ..moveTo(4, 9.5)
    ..lineTo(8, 9.5)
    ..lineTo(12.5, 5.5)
    ..lineTo(12.5, 18.5)
    ..lineTo(8, 14.5)
    ..lineTo(4, 14.5)
    ..close();

  static Path _volumeOff() => _speaker()
    ..moveTo(16, 9.5)
    ..lineTo(21, 14.5)
    ..moveTo(21, 9.5)
    ..lineTo(16, 14.5);

  static Path _volumeLow() => _speaker()
    ..moveTo(15.5, 9.5)
    ..arcToPoint(const Offset(15.5, 14.5), radius: const Radius.circular(3.5));

  static Path _volumeHigh() => _volumeLow()
    ..moveTo(18, 6.5)
    ..arcToPoint(const Offset(18, 17.5), radius: const Radius.circular(6.5));

  /// A record: used where a song has no artwork.
  static Path _disc() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 8))
    ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 2.5));
}
