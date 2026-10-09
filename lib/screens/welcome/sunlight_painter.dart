import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/welcome_timeline.dart';

/// The light around the welcome sun: a soft glow and a ring of slow rays.
/// It is centred on the box it is given and paints well beyond it, so the
/// sun itself is the child of the CustomPaint.
class SunlightPainter extends CustomPainter {
  /// How far the glow reaches, and how far the long rays do.
  static const double glowRadius = 170;
  static const double rayLength = 150;
  static const int rayCount = 16;

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
    final inner = discRadius * 1.15;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        rayLength,
        [
          AppColors.goldLight.withAlpha(alphaFor(0.55 * rays)),
          AppColors.goldLight.withAlpha(0),
        ],
        [inner / rayLength, 1.0],
      );

    for (var i = 0; i < rayCount; i++) {
      final angle = rotation + i * 2 * math.pi / rayCount;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final across = Offset(-direction.dy, direction.dx);
      // Every other ray is shorter, so the ring looks hand-drawn.
      final reach = i.isEven ? rayLength : rayLength * 0.7;
      final base = center + direction * inner;
      final tip = center + direction * reach;
      final path = Path()
        ..moveTo(base.dx + across.dx * 4, base.dy + across.dy * 4)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(base.dx - across.dx * 4, base.dy - across.dy * 4)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(SunlightPainter old) =>
      old.bloom != bloom ||
      old.rays != rays ||
      old.breath != breath ||
      old.rotation != rotation;
}
