import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/swar_glyphs.dart';

/// Draws one [SwarGlyph]. Takes its size and colour from the surrounding
/// IconTheme when none are given, like the stock Icon does.
/// The stroke scales with the size, so it looks the same at 18 and at 54.
class SwarIcon extends StatelessWidget {
  final SwarGlyph glyph;
  final double? size;
  final Color? color;

  const SwarIcon({super.key, required this.glyph, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    final tint = color ?? theme.color ?? AppColors.textPrimary;
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(painter: _GlyphPainter(glyph, tint)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final SwarGlyph glyph;
  final Color color;

  const _GlyphPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final shape = SwarGlyphs.shapeOf(glyph);
    canvas.save();
    canvas.scale(size.width / SwarGlyphs.grid);

    final fill = shape.fill;
    if (fill != null) {
      canvas.drawPath(
        fill,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color,
      );
    }
    final stroke = shape.stroke;
    if (stroke != null) {
      canvas.drawPath(
        stroke,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = SwarGlyphs.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}
