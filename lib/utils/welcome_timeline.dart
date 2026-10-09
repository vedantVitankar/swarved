/// A stretch of a 0 to 1 timeline: it starts at [start] and ends at [end].
class TimeSpan {
  final double start;
  final double end;

  const TimeSpan(this.start, this.end);

  /// 0 before the span, 1 after it, and a straight line from 0 to 1 inside.
  double at(double t) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }
}

/// When each part of the welcome screen happens. Every number that shapes
/// the animation lives here, so it can be tuned in one place.
///
/// The intro is one timeline from 0 to 1 and each part gets a [TimeSpan] of
/// it. The exit plays when she taps "Come in".
class WelcomeTimeline {
  WelcomeTimeline._();

  static const introDuration = Duration(milliseconds: 4600);
  static const exitDuration = Duration(milliseconds: 1300);

  /// With reduced motion the screen only fades away, and quickly.
  static const reducedExitDuration = Duration(milliseconds: 250);

  /// One slow loop: the drifting specks, the breathing sun, the button glow.
  static const ambientDuration = Duration(seconds: 14);

  // The intro, as fractions of [introDuration].
  static const sunRise = TimeSpan(0.00, 0.30);
  static const glowBloom = TimeSpan(0.05, 0.45);
  static const rays = TimeSpan(0.22, 0.55);
  static const dawn = TimeSpan(0.00, 0.50);
  static const motes = TimeSpan(0.20, 0.55);
  static const title = TimeSpan(0.30, 0.60);
  static const line = TimeSpan(0.56, 0.86);
  static const signature = TimeSpan(0.84, 0.94);
  static const button = TimeSpan(0.90, 1.00);

  // The exit, as fractions of [exitDuration].
  static const contentOut = TimeSpan(0.00, 0.28);
  static const sunSwell = TimeSpan(0.00, 0.80);
  static const overlayOut = TimeSpan(0.55, 1.00);
}

/// 0 to 255 for an opacity from 0 to 1, for Color.withAlpha.
int alphaFor(double opacity) {
  if (opacity <= 0) return 0;
  if (opacity >= 1) return 255;
  return (opacity * 255).round();
}
