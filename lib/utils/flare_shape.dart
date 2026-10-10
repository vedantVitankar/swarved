import 'dart:math' as math;
import 'dart:ui';

/// The outline of one flare of the welcome sun, drawn pointing along the
/// positive x axis from a sun centred on the origin. Pure geometry, so its
/// shape can be tested without a screen.
///
/// A flare is a slim flame: widest at its base, tapering to a sharp tip, and
/// bending the way the sun turns. On screen (y runs downwards) a positive
/// [bend] sweeps the tip clockwise, so rotating the whole flare by an angle
/// turns it round the sun like the arm of a pinwheel.
class FlareShape {
  /// Distance from the sun's centre to the flare's base.
  final double inner;

  /// How far the flare reaches outwards from its base, before it bends.
  final double length;

  /// Half the width across the base.
  final double halfWidth;

  /// How far the tip moves sideways, as a fraction of [length]. Positive is
  /// clockwise.
  final double bend;

  /// A small S in the flame, as a fraction of [length], so it reads as
  /// hand-drawn rather than as a plain arc.
  final double wave;

  const FlareShape({
    required this.inner,
    required this.length,
    required this.halfWidth,
    required this.bend,
    this.wave = 0,
  });

  /// How quickly the flare narrows. A little above 1 the sides curve gently
  /// inwards, which gives the sharp, flame-like tip.
  static const double _taper = 1.05;

  /// How many steps each side is drawn in. Plenty for a smooth line.
  static const int _steps = 14;

  /// A flare of a given [arc]: how long it is along its own curve, tip to
  /// base, rather than how far it reaches outwards. The more it bends, the
  /// further out a flare of the same arc stops short.
  factory FlareShape.withArc({
    required double inner,
    required double arc,
    required double halfWidth,
    required double bend,
    double wave = 0,
  }) {
    // The curve scales with its length, so a flare of length 1 says how long
    // the curve is for every other length.
    final unit = FlareShape(
      inner: 0,
      length: 1,
      halfWidth: 0,
      bend: bend,
      wave: wave,
    ).arcLength;
    return FlareShape(
      inner: inner,
      length: arc / unit,
      halfWidth: halfWidth,
      bend: bend,
      wave: wave,
    );
  }

  /// The point of the flare.
  Offset get tip => _centre(1);

  /// How far the tip is from the sun's centre.
  double get reach => tip.distance;

  /// How long the flare is along its own curve, from base to tip.
  double get arcLength {
    const samples = 200;
    var total = 0.0;
    var last = _centre(0);
    for (var i = 1; i <= samples; i++) {
      final next = _centre(i / samples);
      total += (next - last).distance;
      last = next;
    }
    return total;
  }

  /// The middle of the flare, [u] of the way from base (0) to tip (1).
  Offset _centre(double u) {
    return Offset(
      inner + u * length,
      length * (bend * u * u + wave * math.sin(2 * math.pi * u)),
    );
  }

  /// The way the middle of the flare points at [u], as a unit vector.
  Offset _direction(double u) {
    final dy = length *
        (2 * bend * u + wave * 2 * math.pi * math.cos(2 * math.pi * u));
    final dx = length;
    final size = math.sqrt(dx * dx + dy * dy);
    return Offset(dx / size, dy / size);
  }

  double _half(double u) => halfWidth * math.pow(1 - u, _taper).toDouble();

  /// Both sides of the flare, from one side of the base up to the tip and
  /// back down the other. Left open across the base: filled, it closes by
  /// itself; stroked, there is no line across the foot to cut the flare off
  /// from the sun.
  Path path() {
    final minus = <Offset>[];
    final plus = <Offset>[];
    for (var i = 0; i <= _steps; i++) {
      final u = i / _steps;
      final centre = _centre(u);
      final along = _direction(u);
      // Perpendicular to the way it points, towards the side it bends to.
      final side = Offset(-along.dy, along.dx) * _half(u);
      minus.add(centre - side);
      plus.add(centre + side);
    }

    final path = Path()..moveTo(minus.first.dx, minus.first.dy);
    _smoothThrough(path, minus);
    _smoothThrough(path, plus.reversed.toList());
    return path;
  }

  /// Continues [path] through [points] as a smooth line, starting from the
  /// first of them, which is where the path already is.
  static void _smoothThrough(Path path, List<Offset> points) {
    for (var i = 1; i < points.length - 1; i++) {
      final here = points[i];
      final next = points[i + 1];
      path.quadraticBezierTo(
        here.dx,
        here.dy,
        (here.dx + next.dx) / 2,
        (here.dy + next.dy) / 2,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
  }
}
