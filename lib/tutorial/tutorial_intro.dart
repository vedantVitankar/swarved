import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../content/words.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/tutorial_timeline.dart';
import 'tutorial_controller.dart';

/// Sits over a blank Home and does the opening: types the greeting in the
/// middle of the screen, glides it up to where the real greeting sits, and
/// then lets Home fade in around it. It drives the [TutorialController]
/// stage by stage, and takes every tap meanwhile so nothing underneath
/// answers early.
///
/// Waits for the controller to reach `typing` before it starts. With
/// reduced motion it skips the show and hands over at once.
class TutorialIntro extends StatefulWidget {
  final TutorialController controller;

  const TutorialIntro({super.key, required this.controller});

  @override
  State<TutorialIntro> createState() => _TutorialIntroState();
}

class _TutorialIntroState extends State<TutorialIntro>
    with SingleTickerProviderStateMixin {
  /// The greeting is a little larger while it is typed in the middle.
  static const double _maxScale = 1.3;

  /// Where it lands if the real greeting can't be found.
  static const Offset _fallbackTarget = Offset(16, 72);

  late final String _text = Words.greeting(DateTime.now());
  late final AnimationController _master;
  late final double _textWidth;
  late final double _textHeight;
  late final int _glideStartMs;
  late final int _glideEndMs;
  int _endMs = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    final measure = TextPainter(
      text: TextSpan(text: _text, style: AppType.display),
      textDirection: TextDirection.ltr,
    )..layout();
    _textWidth = measure.width;
    _textHeight = measure.height;
    measure.dispose();

    final letters = _text.length;
    _glideStartMs = TutorialTimeline.glideStart(letters).inMilliseconds;
    _glideEndMs = TutorialTimeline.glideEnd(letters).inMilliseconds;
    _endMs = TutorialTimeline.end(letters).inMilliseconds;
    _master = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _endMs),
    )..addListener(_onTick);
    widget.controller.addListener(_onStage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onStage();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStage);
    _master.dispose();
    super.dispose();
  }

  /// Starts the show when the welcome hands over.
  void _onStage() {
    if (_running || widget.controller.stage != TutorialStage.typing) return;
    _running = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      widget.controller
        ..glide()
        ..reveal()
        ..finish();
      return;
    }
    // With the song first, only the song fades in at the end of the
    // opening, so it is over sooner. Known now that the opening has begun.
    final blocks =
        widget.controller.songFirst ? 1 : TutorialTimeline.revealBlocks;
    _endMs = TutorialTimeline.end(_text.length, blocks: blocks).inMilliseconds;
    _master.duration = Duration(milliseconds: _endMs);
    _master.forward();
  }

  /// Hands each stage on as its moment arrives. One call can pass several
  /// stages at once, for instance if a frame came very late.
  void _onTick() {
    final ms = _master.value * _endMs;
    final controller = widget.controller;
    if (controller.stage == TutorialStage.typing && ms >= _glideStartMs) {
      controller.glide();
    }
    if (controller.stage == TutorialStage.gliding && ms >= _glideEndMs) {
      controller.reveal();
    }
    if (controller.stage == TutorialStage.revealing && ms >= _endMs) {
      controller.finish();
    }
  }

  /// Where the real greeting sits, in this overlay's own coordinates.
  Offset _target() {
    final mine = context.findRenderObject();
    final theirs =
        widget.controller.greetingKey.currentContext?.findRenderObject();
    if (mine is! RenderBox || theirs is! RenderBox) return _fallbackTarget;
    if (!theirs.attached || !theirs.hasSize) return _fallbackTarget;
    return mine.globalToLocal(theirs.localToGlobal(Offset.zero));
  }

  static double _unit(double value) => math.max(0.0, math.min(1.0, value));

  static double _between(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, box) => AnimatedBuilder(
            animation: _master,
            builder: (context, _) => _greeting(box.biggest),
          ),
        ),
      ),
    );
  }

  Widget _greeting(Size screen) {
    final stage = widget.controller.stage;
    // Before the show, and once Home's own greeting has taken over, there
    // is nothing to draw.
    if (stage == TutorialStage.blank ||
        stage == TutorialStage.revealing ||
        stage == TutorialStage.touring ||
        stage == TutorialStage.finished ||
        stage == TutorialStage.off) {
      return const SizedBox.shrink();
    }

    final elapsed = Duration(milliseconds: (_master.value * _endMs).round());
    final typing = stage == TutorialStage.typing;

    // Never so wide that the larger greeting runs off the screen.
    final startScale = _textWidth <= 0
        ? 1.0
        : math.max(1.0, math.min(_maxScale, (screen.width - 64) / _textWidth));
    final start = Offset(
      (screen.width - _textWidth * startScale) / 2,
      screen.height * 0.42 - _textHeight * startScale / 2,
    );

    final glideT = Curves.easeInOutCubic.transform(
      _unit((elapsed.inMilliseconds - _glideStartMs) /
          (_glideEndMs - _glideStartMs)),
    );
    final target = _target();
    final scale = _between(startScale, 1.0, glideT);
    final x = _between(start.dx, target.dx, glideT);
    final y = _between(start.dy, target.dy, glideT);

    final shown = typing
        ? TutorialTimeline.lettersShown(elapsed, _text.length)
        : _text.length;
    // A gold caret blinks while the letters come, and goes when it glides.
    final caretOn = typing && (elapsed.inMilliseconds ~/ 450).isEven;

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: Transform.translate(
            offset: Offset(x, y),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                // Room for the caret after the last letter.
                width: _textWidth + 24,
                child: Text.rich(
                  TextSpan(
                    text: _text.substring(0, shown),
                    children: [
                      TextSpan(
                        text: typing ? '|' : '',
                        style: TextStyle(
                          color: caretOn ? AppColors.gold : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                  style: AppType.display,
                  softWrap: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
