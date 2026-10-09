import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/welcome_timeline.dart';

/// Everything behind the welcome screen's words: a warm glow from below, like
/// a sunrise just out of sight, and golden specks drifting up through it.
class WelcomeSky extends StatelessWidget {
  final Animation<double> intro;
  final Animation<double> ambient;
  final Animation<double> exit;

  /// With reduced motion there are no specks, only the still glow.
  final bool reduceMotion;

  const WelcomeSky({
    super.key,
    required this.intro,
    required this.ambient,
    required this.exit,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SkyPainter(
          intro: intro,
          ambient: ambient,
          exit: exit,
          reduceMotion: reduceMotion,
        ),
      ),
    );
  }
}

/// One drifting speck. All its numbers are fixed when the app starts, so the
/// sky looks the same every time.
class _Mote {
  /// Across the screen, 0 to 1.
  final double x;

  /// Where in its climb it is when the loop starts, 0 to 1.
  final double phase;

  /// Whole climbs per loop, so the loop joins up without a jump.
  final double climbs;
  final double radius;

  /// How far it wanders from side to side, as a fraction of the width.
  final double sway;

  const _Mote({
    required this.x,
    required this.phase,
    required this.climbs,
    required this.radius,
    required this.sway,
  });
}

class _SkyPainter extends CustomPainter {
  final Animation<double> intro;
  final Animation<double> ambient;
  final Animation<double> exit;
  final bool reduceMotion;

  _SkyPainter({
    required this.intro,
    required this.ambient,
    required this.exit,
    required this.reduceMotion,
  }) : super(repaint: Listenable.merge([intro, ambient, exit]));

  static const int _moteCount = 26;

  static final List<_Mote> _motes = _makeMotes();

  static List<_Mote> _makeMotes() {
    final random = math.Random(14);
    return List.generate(_moteCount, (_) {
      return _Mote(
        x: random.nextDouble(),
        phase: random.nextDouble(),
        climbs: random.nextBool() ? 1.0 : 2.0,
        radius: 0.8 + random.nextDouble() * 1.8,
        sway: 0.01 + random.nextDouble() * 0.025,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Everything but the glow leaves with the words.
    final leaving = WelcomeTimeline.contentOut.at(exit.value);
    _paintDawn(canvas, size, 1 - leaving * 0.5);
    if (!reduceMotion) _paintMotes(canvas, size, 1 - leaving);
  }

  void _paintDawn(Canvas canvas, Size size, double strength) {
    final dawn = WelcomeTimeline.dawn.at(intro.value) * strength;
    if (dawn <= 0) return;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height),
        Offset(0, size.height * 0.2),
        [
          AppColors.maroon.withAlpha(alphaFor(0.85 * dawn)),
          AppColors.maroon.withAlpha(0),
        ],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintMotes(Canvas canvas, Size size, double strength) {
    final visible = WelcomeTimeline.motes.at(intro.value) * strength;
    if (visible <= 0) return;

    final paint = Paint();
    for (final mote in _motes) {
      // 0 at the bottom edge, 1 at the top.
      final climb = (mote.phase + ambient.value * mote.climbs) % 1.0;
      final y = size.height * (1.05 - 1.1 * climb);
      final sway = math.sin((climb * 2 + mote.phase) * 2 * math.pi);
      final x = size.width * (mote.x + mote.sway * sway);
      // Fades in at the bottom and out at the top.
      final glow = math.sin(climb * math.pi) * visible;
      if (glow <= 0) continue;

      paint.color = AppColors.goldLight.withAlpha(alphaFor(0.12 * glow));
      canvas.drawCircle(Offset(x, y), mote.radius * 3.5, paint);
      paint.color = AppColors.goldLight.withAlpha(alphaFor(0.6 * glow));
      canvas.drawCircle(Offset(x, y), mote.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.intro != intro ||
      old.ambient != ambient ||
      old.exit != exit ||
      old.reduceMotion != reduceMotion;
}
