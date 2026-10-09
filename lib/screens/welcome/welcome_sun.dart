import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/welcome_timeline.dart';
import '../../widgets/sun_mark.dart';
import 'sunlight_painter.dart';

/// The sun on the welcome screen. It rises, glows, sends out slow rays and
/// breathes. When she comes in it swells until it fills the screen.
class WelcomeSun extends StatelessWidget {
  final Animation<double> intro;
  final Animation<double> ambient;
  final Animation<double> exit;

  /// With reduced motion the sun just stands there, already risen.
  final bool reduceMotion;

  /// Half the size, on the pages after the first, so it stays as a small
  /// sun above the words instead of taking the whole page.
  final bool compact;

  const WelcomeSun({
    super.key,
    required this.intro,
    required this.ambient,
    required this.exit,
    required this.reduceMotion,
    this.compact = false,
  });

  static const double _stageHeight = 200;
  static const double _compactHeight = 104;
  static const double _compactScale = 0.5;
  static const double _discSize = 96;

  /// How far below its place the sun starts, before it rises.
  static const double _riseDistance = 140;

  /// How much bigger the sun gets when she comes in.
  static const double _maxSwell = 7;

  /// How much the sun grows and shrinks as it breathes.
  static const double _breathing = 0.03;

  @override
  Widget build(BuildContext context) {
    // Its own layer, so the sun repainting every frame doesn't drag the
    // words and buttons around it into repainting too.
    return RepaintBoundary(
      child: SizedBox(
        height: compact ? _compactHeight : _stageHeight,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([intro, ambient, exit]),
            builder: (context, _) {
              final t = intro.value;
              final rise = Curves.easeOutCubic.transform(
                WelcomeTimeline.sunRise.at(t),
              );
              final bloom = Curves.easeOut.transform(
                WelcomeTimeline.glowBloom.at(t),
              );
              final rays = Curves.easeOut.transform(
                WelcomeTimeline.rays.at(t),
              );
              final turn = ambient.value * 2 * math.pi;
              final breath = reduceMotion ? 0.0 : math.sin(turn);
              final swell = reduceMotion
                  ? 0.0
                  : Curves.easeInCubic.transform(
                      WelcomeTimeline.sunSwell.at(exit.value),
                    );
              final scale = (1 + _breathing * breath) *
                  (1 + _maxSwell * swell) *
                  (compact ? _compactScale : 1.0);

              return Transform.translate(
                offset: Offset(0, (1 - rise) * _riseDistance),
                // The sun thins out as it swells, so the light it floods
                // the screen with stays warm instead of blinding.
                child: Opacity(
                  opacity: rise * (1 - 0.6 * swell),
                  child: Transform.scale(
                    scale: scale,
                    child: CustomPaint(
                      painter: SunlightPainter(
                        bloom: bloom,
                        rays: rays,
                        breath: breath,
                        rotation: reduceMotion
                            ? 0.0
                            : ambient.value *
                                2 *
                                math.pi /
                                SunlightPainter.rayCount,
                      ),
                      child: const SunMark(size: _discSize),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
