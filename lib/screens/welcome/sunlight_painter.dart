import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/flare_shape.dart';
import '../../utils/welcome_timeline.dart';

/// The light around the welcome sun: a soft glow and a ring of curved,
/// flame-like flares. Each flare is drawn twice: a soft gold fill that fades
/// outwards, and a fine outline that stays brighter, going from the sun's
/// hot core colour at the base to a warm gold at the tips. It is centred on
/// the box it is given and paints well beyond it, so the sun itself is the
/// child of the CustomPaint.
class SunlightPainter extends CustomPainter {
  /// How far the glow reaches.
  static const double glowRadius = 170;
  static const int rayCount = 16;

  /// The flares come in a long one and a short one, over and over, so the
  /// ring looks the same every [patternLength] flares.
  static const int patternLength = 2;

  /// How far the ring turns in one ambient loop. It is a whole pattern, not
  /// one flare, so the loop joins up: at the end every long flare lands
  /// exactly where a long flare was, and nothing pops.
  static const double loopTurn = patternLength * 2 * math.pi / rayCount;

  /// 0 to 1: how much of the glow has bloomed.
  final double bloom;

  /// 0 to 1: how visible the rays are.
  final double rays;

  /// -1 to 1: the sun breathing in and out.
  final double breath;

  /// How far the ring of rays has turned, in radians.
  final double rotation;

  const SunlightPainter({
    required this.bloom,
    required this.rays,
    required this.breath,
    required this.rotation,
  });

  /// Where the flares start, as a multiple of the sun's radius: almost
  /// touching it, as in the drawing this is after.
  static const double _baseAt = 1.06;

  /// How long the long flare is along its curve, as a multiple of the sun's
  /// diameter, and how long the short one is next to the long one.
  static const double longArc = 0.9;
  static const double shortArc = 0.52;

  /// The thin line round each flare.
  static const double _lineWidth = 1.3;

  static double? _shapesFor;
  static List<Path> _shapes = const [];
  static double _longReach = 0;

  /// The long flare and the short one, built once for a sun of this size
  /// and used for every flare in the ring, every frame. Also remembers how
  /// far the long one reaches, which is where the colours finish fading.
  static List<Path> _flares(double discRadius) {
    if (_shapesFor == discRadius) return _shapes;
    final inner = discRadius * _baseAt;
    final long = FlareShape.withArc(
      inner: inner,
      arc: longArc * 2 * discRadius,
      halfWidth: 8.5,
      bend: 0.62,
      wave: 0.030,
    );
    final short = FlareShape.withArc(
      inner: inner,
      arc: longArc * 2 * discRadius * shortArc,
      halfWidth: 6.5,
      bend: 0.68,
      wave: 0.026,
    );
    _shapes = [long.path(), short.path()];
    _longReach = long.reach;
    _shapesFor = discRadius;
    return _shapes;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    _paintGlow(canvas, center);
    _paintRays(canvas, center, size.shortestSide / 2);
  }

  void _paintGlow(Canvas canvas, Offset center) {
    if (bloom <= 0) return;
    final radius = glowRadius * (0.8 + 0.2 * bloom) * (1 + 0.04 * breath);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          AppColors.gold.withAlpha(alphaFor(0.5 * bloom)),
          AppColors.gold.withAlpha(alphaFor(0.16 * bloom)),
          AppColors.gold.withAlpha(0),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _paintRays(Canvas canvas, Offset center, double discRadius) {
    if (rays <= 0) return;
    final inner = discRadius * _baseAt;
    final flares = _flares(discRadius);
    final rayLength = _longReach;

    // The fill: soft gold, fading to nothing at the tips.
    final fill = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        rayLength,
        [
          AppColors.goldLight.withAlpha(alphaFor(0.55 * rays)),
          AppColors.goldLight.withAlpha(0),
        ],
        [inner / rayLength, 1.0],
      );

    // The outline: the sun's bright core colour at the base, warm gold
    // further out, and still faintly there at the tips so each flare keeps
    // its shape.
    final reach = rayLength * 1.06;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.radial(
        Offset.zero,
        reach,
        [
          AppColors.goldLight.withAlpha(alphaFor(0.95 * rays)),
          AppColors.gold.withAlpha(alphaFor(0.8 * rays)),
          AppColors.gold.withAlpha(alphaFor(0.18 * rays)),
        ],
        [inner / reach, 0.5, 1.0],
      );

    // Each flare is the same shape, turned a step further round the sun.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    const step = 2 * math.pi / rayCount;
    for (var i = 0; i < rayCount; i++) {
      final flare = flares[i % patternLength];
      canvas.drawPath(flare, fill);
      canvas.drawPath(flare, line);
      canvas.rotate(step);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SunlightPainter old) =>
      old.bloom != bloom ||
      old.rays != rays ||
      old.breath != breath ||
      old.rotation != rotation;
}
