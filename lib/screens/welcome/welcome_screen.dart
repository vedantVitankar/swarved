import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../content/labels.dart';
import '../../content/words.dart';
import '../../models/note_line.dart';
import '../../models/welcome_settings.dart';
import '../../services/content_service.dart';
import '../../theme/colors.dart';
import '../../theme/shape.dart';
import '../../theme/swar_glyphs.dart';
import '../../theme/typography.dart';
import '../../utils/welcome_timeline.dart';
import '../../widgets/swar_icon.dart';
import '../../widgets/swar_outlined_button.dart';
import 'reveal_text.dart';
import 'welcome_dots.dart';
import 'welcome_pages.dart';
import 'welcome_sky.dart';
import 'welcome_sun.dart';

/// The first thing she sees, in four steps: the sun rises and his line
/// appears, then why he made it, then a few notes to swipe through, then a
/// short tour of the app. "Come in" on the last step swells the sun and
/// fades the screen away to the app behind it, then calls [onDone].
///
/// A tap while the first step is still playing skips ahead to its end.
/// "Skip" leaves from any step but the last. With reduced motion everything
/// is simply there, and it only fades out.
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
  int _step = 0;

  static const int _steps = 4;
  static const double _titleSize = 46;
  static const double _lineSize = 28;
  static const double _signatureSize = 24;

  bool get _isLast => _step == _steps - 1;

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

  void _next() {
    if (_leaving) return;
    if (_isLast) {
      _enter();
    } else {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_leaving || _step == 0) return;
    setState(() => _step--);
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
                child: Column(
                  children: [
                    _topBar(),
                    Expanded(child: _stage(settings)),
                    _controls(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The step on show, with a short crossfade when it changes. Every page
  /// starts at the same height, so nothing jumps while two are on screen.
  Widget _stage(WelcomeSettings settings) {
    return LayoutBuilder(
      builder: (context, box) {
        // A little lower on tall screens, so the first step sits like the
        // single welcome did, and never so low that a short one scrolls.
        final top = math.max(8.0, math.min(90.0, (box.maxHeight - 460) * 0.28));
        return SingleChildScrollView(
          // The sun's glow reaches past the top of its own box.
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(32, top, 32, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: AnimatedSwitcher(
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, if (current != null) current],
                ),
                child: KeyedSubtree(
                  key: ValueKey<int>(_step),
                  child: _page(settings),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The sun, then the words of the current step. The sun stays put when
  /// she comes in; only the words leave.
  Widget _page(WelcomeSettings settings) {
    final Widget words = switch (_step) {
      0 => _firstWords(settings),
      1 => WelcomeStoryPage(
          paragraphs:
              settings.story.isEmpty ? Words.welcomeStory : settings.story,
          signature: settings.signature ?? Words.welcomeSignature,
          instant: _reduceMotion,
        ),
      2 => WelcomeNotesPage(
          notes: settings.notes.isEmpty
              ? [for (final note in Words.welcomeNotes) NoteLine(note: note)]
              : settings.notes,
          instant: _reduceMotion,
        ),
      _ => WelcomeTourPage(instant: _reduceMotion),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WelcomeSun(
          intro: _intro,
          ambient: _ambient,
          exit: _exit,
          reduceMotion: _reduceMotion,
          compact: _step > 0,
        ),
        _leavingWithTheWords(words),
      ],
    );
  }

  /// Her name and his line, appearing letter by letter and word by word.
  Widget _firstWords(WelcomeSettings settings) {
    final line = settings.line ?? Words.welcomeLine;
    final signature = settings.signature ?? Words.welcomeSignature;

    // Its own layer, so the sun's repainting never repaints the words.
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Never wraps: with big system text, or while the letters are
          // still wide apart, it shrinks to fit instead.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RevealText(
              text: Words.swarnima,
              style: AppType.display.copyWith(fontSize: _titleSize),
              progress: _intro,
              span: WelcomeTimeline.title,
              letters: true,
              extraSpacing: 9,
            ),
          ),
          const SizedBox(height: 18),
          RevealText(
            text: line,
            style: AppType.note.copyWith(fontSize: _lineSize),
            progress: _intro,
            span: WelcomeTimeline.line,
          ),
          const SizedBox(height: 8),
          RevealText(
            text: signature,
            style: AppType.note.copyWith(fontSize: _signatureSize),
            progress: _intro,
            span: WelcomeTimeline.signature,
            letters: true,
          ),
        ],
      ),
    );
  }

  /// Back on the left, Skip on the right. They arrive with the button.
  Widget _topBar() {
    return _leavingWithTheWords(
      _whenArrived(
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (_step == 0)
                  const SizedBox(width: 48)
                else
                  IconButton(
                    tooltip: Labels.welcomeBack,
                    onPressed: _back,
                    icon: const SwarIcon(
                      glyph: SwarGlyph.back,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                if (!_isLast)
                  TextButton(
                    onPressed: _enter,
                    child: Text(Labels.welcomeSkip, style: AppType.caption),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The dots and the one button: Next, and on the last step Come in.
  Widget _controls() {
    return _leavingWithTheWords(
      _whenArrived(
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WelcomeDots(count: _steps, index: _step),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: _glow()),
                  SwarOutlinedButton(
                    label: _isLast ? Labels.welcomeEnter : Labels.welcomeNext,
                    onPressed: _next,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A soft rose halo that slowly swells and fades, like breathing. The halo
  /// itself is drawn once and kept; only its opacity changes each frame, so
  /// the blur is never redone.
  Widget _glow() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, halo) {
        final pulse = _reduceMotion
            ? 0.5
            : (math.sin(_ambient.value * 2 * math.pi) + 1) / 2;
        return Opacity(opacity: 0.4 + 0.6 * pulse, child: halo);
      },
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppShape.button),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withAlpha(alphaFor(0.2)),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The controls arrive last. Until they are nearly there they let taps
  /// through, so an early tap skips ahead instead of doing nothing.
  Widget _whenArrived(Widget child) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
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
    );
  }

  /// The words and the buttons fade up and away as she comes in.
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
}
