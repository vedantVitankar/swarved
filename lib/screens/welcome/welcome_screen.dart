import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/welcome_settings.dart';
import '../../services/content_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/typography.dart';
import '../../utils/welcome_timeline.dart';
import '../../widgets/swar_outlined_button.dart';
import 'reveal_text.dart';
import 'welcome_sky.dart';
import 'welcome_sun.dart';

/// The first thing she sees: the sun rises, her name appears, then a line in
/// his handwriting and his signature, and a single way in.
///
/// A tap while it is still playing skips ahead to the end. "Come in" swells
/// the sun and fades the screen away to what is behind it, then calls
/// [onDone]. With reduced motion everything is simply there, and it only
/// fades out.
class WelcomeScreen extends StatefulWidget {
  /// Called once the screen has faded away completely.
  final VoidCallback onDone;

  const WelcomeScreen({super.key, required this.onDone});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: WelcomeTimeline.introDuration,
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: WelcomeTimeline.ambientDuration,
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: WelcomeTimeline.exitDuration,
  );

  bool _started = false;
  bool _reduceMotion = false;
  bool _leaving = false;

  static const double _titleSize = 46;
  static const double _lineSize = 28;
  static const double _signatureSize = 24;

  @override
  void initState() {
    super.initState();
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// A tap anywhere while the intro plays jumps to the end of it.
  void _skipIntro() {
    if (_intro.isAnimating) _intro.value = 1;
  }

  void _enter() {
    if (_leaving) return;
    setState(() => _leaving = true);
    if (_reduceMotion) _exit.duration = WelcomeTimeline.reducedExitDuration;
    _exit.forward();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.select<ContentService, WelcomeSettings>(
      (content) => content.welcomeSettings,
    );
    final line = settings.line ?? Words.welcomeLine;
    final signature = settings.signature ?? Words.welcomeSignature;

    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final gone = Curves.easeOut.transform(
          WelcomeTimeline.overlayOut.at(_exit.value),
        );
        return Opacity(opacity: 1 - gone, child: child);
      },
      child: Scaffold(
        backgroundColor: AppColors.base,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skipIntro,
          child: Stack(
            fit: StackFit.expand,
            children: [
              WelcomeSky(
                intro: _intro,
                ambient: _ambient,
                exit: _exit,
                reduceMotion: _reduceMotion,
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    // The sun's glow reaches past the top of its own box.
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WelcomeSun(
                            intro: _intro,
                            ambient: _ambient,
                            exit: _exit,
                            reduceMotion: _reduceMotion,
                          ),
                          _leavingWithTheWords(
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Never wraps: with big system text, or while
                                // the letters are still wide apart, it
                                // shrinks to fit instead.
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: RevealText(
                                    text: Words.swarnima,
                                    style: AppType.display.copyWith(
                                      fontSize: _titleSize,
                                    ),
                                    progress: _intro,
                                    span: WelcomeTimeline.title,
                                    letters: true,
                                    extraSpacing: 9,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                RevealText(
                                  text: line,
                                  style: AppType.note.copyWith(
                                    fontSize: _lineSize,
                                  ),
                                  progress: _intro,
                                  span: WelcomeTimeline.line,
                                ),
                                const SizedBox(height: 8),
                                RevealText(
                                  text: signature,
                                  style: AppType.note.copyWith(
                                    fontSize: _signatureSize,
                                  ),
                                  progress: _intro,
                                  span: WelcomeTimeline.signature,
                                  letters: true,
                                ),
                                const SizedBox(height: 36),
                                _enterButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The words and the button fade up and away as she comes in.
  Widget _leavingWithTheWords(Widget words) {
    return AnimatedBuilder(
      animation: _exit,
      builder: (context, child) {
        final out = Curves.easeIn.transform(
          WelcomeTimeline.contentOut.at(_exit.value),
        );
        return Opacity(
          opacity: 1 - out,
          child: Transform.translate(
            offset: Offset(0, -16 * out),
            child: child,
          ),
        );
      },
      child: words,
    );
  }

  /// The button arrives last. Until it is nearly there it lets taps through,
  /// so an early tap skips ahead instead of doing nothing.
  Widget _enterButton() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final arrive = Curves.easeOut.transform(
          WelcomeTimeline.button.at(_intro.value),
        );
        return IgnorePointer(
          ignoring: arrive < 0.6 || _leaving,
          child: Opacity(
            opacity: arrive,
            child: Transform.translate(
              offset: Offset(0, (1 - arrive) * 12),
              child: child,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _ambient,
        builder: (context, child) {
          // A soft rose halo that slowly swells and fades, like breathing.
          final pulse = _reduceMotion
              ? 0.5
              : (math.sin(_ambient.value * 2 * math.pi) + 1) / 2;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppShape.button),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withAlpha(
                    alphaFor(0.08 + 0.14 * pulse),
                  ),
                  blurRadius: 16 + 10 * pulse,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: SwarOutlinedButton(
          label: Labels.welcomeEnter,
          onPressed: _enter,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        ),
      ),
    );
  }
}
