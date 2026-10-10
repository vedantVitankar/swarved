import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../content/words.dart';
import '../screens/welcome/welcome_dots.dart';
import '../theme/colors.dart';
import '../theme/shape.dart';
import '../theme/typography.dart';
import '../utils/spotlight_layout.dart';
import '../utils/welcome_timeline.dart';
import '../widgets/swar_outlined_button.dart';
import 'tutorial_controller.dart';
import 'tutorial_step.dart';

/// The tour: Home dims, and one part of it at a time stays lit while a few
/// handwritten words say what it is. The first stop asks her to press play
/// on the tutorial song; from then on the song plays under the rest of the
/// tour. Nothing under the dimmed screen answers a tap, except the song's
/// card on that first stop.
///
/// It walks the [TutorialController] through its steps, and fades out
/// before the controller says the tutorial is over.
class TutorialSpotlight extends StatefulWidget {
  final TutorialController controller;

  /// His own captions by step name; a step without one uses the default.
  final Map<String, String> captions;

  /// Fires when playback changes, and says whether the tutorial's song is
  /// playing. Both null when there is no song.
  final Listenable? playback;
  final bool Function()? songIsPlaying;

  /// Whether Home has no folders yet, so that step can say where they will
  /// appear. Null counts as folders present.
  final bool Function()? foldersEmpty;

  /// Fires when the library changes, and says which folder it is reading
  /// (null for none). Choosing a different folder while the tour asks for
  /// one moves the tour on.
  final Listenable? library;
  final String? Function()? folderPath;

  const TutorialSpotlight({
    super.key,
    required this.controller,
    this.captions = const {},
    this.playback,
    this.songIsPlaying,
    this.foldersEmpty,
    this.library,
    this.folderPath,
  });

  @override
  State<TutorialSpotlight> createState() => _TutorialSpotlightState();
}

class _TutorialSpotlightState extends State<TutorialSpotlight>
    with TickerProviderStateMixin {
  static const Duration _fadeTime = Duration(milliseconds: 500);
  static const Duration _moveTime = Duration(milliseconds: 650);

  /// How long she is given to press play before "Continue" appears, in
  /// case the song can't start.
  static const Duration _patience = Duration(seconds: 8);

  static const double _captionMargin = 24;
  static const double _captionMaxWidth = 360;
  static const double _holeRadius = 14;

  late final AnimationController _fade;
  late final AnimationController _move;
  Timer? _patienceTimer;

  /// The song has had its chance to start, so "Continue" may show.
  bool _canContinue = false;

  TutorialStep? _shown;
  String? _folderAtEntry;
  Rect? _from;
  Rect? _drawn;

  /// The step the tour has just left, and where its caption was, so that
  /// caption can fade out where it stood while the hole moves on.
  int _shownIndex = 0;
  TutorialStep? _previous;
  int _previousIndex = 0;
  Rect? _previousHole;
  VoidCallback? _afterFade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: _fadeTime)
      ..addStatusListener(_onFadeStatus);
    _move = AnimationController(vsync: this, duration: _moveTime);

    widget.controller.addListener(_onController);
    widget.playback?.addListener(_onPlayback);
    widget.library?.addListener(_onLibrary);

    _shown = widget.controller.step;
    _shownIndex = widget.controller.stepIndex;
    _enter(_shown);
    _fade.forward();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    widget.playback?.removeListener(_onPlayback);
    widget.library?.removeListener(_onLibrary);
    _fade.dispose();
    _move.dispose();
    _patienceTimer?.cancel();
    super.dispose();
  }

  /// A step has come up: lit parts that are scrolled out of sight are
  /// brought into view, the hole starts its move, and the patience clock for
  /// the play step starts.
  void _enter(TutorialStep? step) {
    if (step == null) return;
    if (step == TutorialStep.addFolder)
      _folderAtEntry = widget.folderPath?.call();
    _move.forward(from: 0);
    // A timer, not an animation: nothing changes on screen while she
    // waits, so nothing should be redrawn every frame.
    _patienceTimer?.cancel();
    if (step == TutorialStep.play) {
      _canContinue = false;
      _patienceTimer = Timer(_patience, () {
        if (mounted) setState(() => _canContinue = true);
      });
    }
    // Two frames on: a step that changes the tab needs the new tab on
    // screen first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = widget.controller.keyFor(step).currentContext;
        if (target == null) return;
        // Does nothing for parts that aren't in a scrolling page.
        Scrollable.ensureVisible(
          target,
          alignment: 0.35,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  void _onController() {
    final step = widget.controller.step;
    if (step == null || step == _shown) return;
    _from = _drawn;
    _previous = _shown;
    _previousIndex = _shownIndex;
    _previousHole = _drawn;
    _shown = step;
    _shownIndex = widget.controller.stepIndex;
    _enter(step);
  }

  /// Pressing play on the tutorial song is what moves the first stop on.
  void _onPlayback() {
    if (widget.controller.step != TutorialStep.play) return;
    if (widget.songIsPlaying?.call() ?? false) widget.controller.advance();
  }

  /// Choosing a folder is what moves the folder step on.
  void _onLibrary() {
    if (widget.controller.step != TutorialStep.addFolder) return;
    final path = widget.folderPath?.call();
    if (path != null && path != _folderAtEntry) widget.controller.advance();
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) return;
    final done = _afterFade;
    _afterFade = null;
    done?.call();
  }

  /// Fades the tour out, then does [done], which ends it.
  void _closeThen(VoidCallback done) {
    if (_afterFade != null) return;
    _afterFade = done;
    _fade.reverse();
  }

  void _skip() => _closeThen(widget.controller.skip);

  void _next() {
    final controller = widget.controller;
    if (controller.stepIndex + 1 >= controller.steps.length) {
      _closeThen(controller.advance);
    } else {
      controller.advance();
    }
  }

  /// Where the lit part is, in this overlay's own coordinates, or null when
  /// it can't be found.
  Rect? _measure(TutorialStep step) {
    final mine = context.findRenderObject();
    final theirs =
        widget.controller.keyFor(step).currentContext?.findRenderObject();
    if (mine is! RenderBox || theirs is! RenderBox) return null;
    if (!mine.hasSize || !theirs.attached || !theirs.hasSize) return null;
    final corner = mine.globalToLocal(theirs.localToGlobal(Offset.zero));
    return corner & theirs.size;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back means skip, so she can never be stuck behind the dimming.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _skip();
      },
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, box) => AnimatedBuilder(
            animation: Listenable.merge([_fade, _move]),
            builder: (context, _) => _content(box.biggest),
          ),
        ),
      ),
    );
  }

  Widget _content(Size screen) {
    final step = _shown;
    if (step == null) return const SizedBox.shrink();

    final target = _measure(step);
    final lit = target == null ? null : SpotlightLayout.hole(target, screen);
    final from = _from;
    final moved = Curves.easeInOutCubic.transform(_move.value);
    final hole =
        lit == null ? null : (from == null ? lit : Rect.lerp(from, lit, moved));
    _drawn = hole;

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScrimPainter(hole: hole, strength: _fade.value),
              ),
            ),
          ),
        ),
        ..._blockers(step, hole, screen),
        ..._captions(step, lit, screen),
      ],
    );
  }

  /// Everything under the dimming takes no taps. On the play step the lit
  /// card is left open, which the four blocks around the hole make room for.
  List<Widget> _blockers(TutorialStep step, Rect? hole, Size screen) {
    const block = AbsorbPointer(child: SizedBox.expand());
    if (!step.isInteractive || hole == null) {
      return const [Positioned.fill(child: block)];
    }
    return [
      Positioned(left: 0, top: 0, right: 0, height: hole.top, child: block),
      Positioned(left: 0, top: hole.bottom, right: 0, bottom: 0, child: block),
      Positioned(
        left: 0,
        top: hole.top,
        width: hole.left,
        height: hole.height,
        child: block,
      ),
      Positioned(
        left: hole.right,
        top: hole.top,
        right: 0,
        height: hole.height,
        child: block,
      ),
    ];
  }

  /// The part of a move in which the old caption fades out, and the part in
  /// which the new one fades in. Between the two there is no caption, so the
  /// card never jumps across the screen while the hole is in motion.
  static const double _captionOutEnd = 0.25;
  static const double _captionInStart = 0.5;

  /// The caption to draw now. A caption always sits beside the part it
  /// belongs to, never beside the moving hole: when the hole travels from
  /// the top of the screen to the bottom, a card that followed it would
  /// leap from below the hole to above it halfway. Instead the old card
  /// fades out where it stood, and the new one fades in where it belongs.
  List<Widget> _captions(TutorialStep step, Rect? lit, Size screen) {
    final previous = _previous;
    final t = _move.value;

    if (previous != null && t < _captionOutEnd) {
      return [
        _placedCard(
          previous,
          _previousIndex,
          _previousHole,
          screen,
          opacity: 1 - t / _captionOutEnd,
          interactive: false,
        ),
      ];
    }

    // The very first step has nothing to wait for.
    final arrived = previous == null
        ? 1.0
        : ((t - _captionInStart) / (1 - _captionInStart)).clamp(0.0, 1.0);
    return [
      _placedCard(
        step,
        _shownIndex,
        lit,
        screen,
        opacity: arrived,
        interactive: arrived >= 1,
      ),
    ];
  }

  Widget _placedCard(
    TutorialStep step,
    int index,
    Rect? hole,
    Size screen, {
    required double opacity,
    required bool interactive,
  }) {
    final card = IgnorePointer(
      ignoring: !interactive,
      child: Opacity(opacity: opacity, child: _card(step, index, screen)),
    );

    // No lit part to point at: the words simply sit in the middle.
    if (hole == null) return Center(child: card);

    const gap = SpotlightLayout.captionGap;
    // Align, not Center: the card should be as tall as it is, not as tall
    // as the room it is given.
    final placed = Align(heightFactor: 1, child: card);
    if (SpotlightLayout.captionAbove(hole, screen)) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: screen.height - hole.top + gap,
        child: placed,
      );
    }
    return Positioned(left: 0, right: 0, top: hole.bottom + gap, child: placed);
  }

  Widget _card(TutorialStep step, int index, Size screen) {
    final controller = widget.controller;
    final text = tutorialCaption(
      step,
      own: widget.captions,
      noFolders: step == TutorialStep.folders &&
          (widget.foldersEmpty?.call() ?? false),
    );
    final isLast = index + 1 >= controller.steps.length;
    final isPlay = step == TutorialStep.play;
    // Pressing play is the only way on, unless the song never starts. The
    // folder can always be left for later.
    final showNext = !isPlay || _canContinue;
    final nextLabel = switch (step) {
      TutorialStep.play => Words.tutorialContinue,
      TutorialStep.addFolder => Words.tutorialNotNow,
      _ => isLast ? Words.tutorialDone : Labels.welcomeNext,
    };

    return FadeTransition(
      opacity: _fade,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              math.min(_captionMaxWidth, screen.width - 2 * _captionMargin),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppShape.card),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WelcomeDots(count: controller.steps.length, index: index),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppType.note.copyWith(
                  fontSize: 26,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(Labels.welcomeSkip, style: AppType.caption),
                  ),
                  const Spacer(),
                  if (showNext)
                    SwarOutlinedButton(
                      label: nextLabel,
                      onPressed: isPlay ? controller.advance : _next,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims the whole screen except the lit hole, which gets a thin gold edge.
class _ScrimPainter extends CustomPainter {
  final Rect? hole;
  final double strength;

  const _ScrimPainter({required this.hole, required this.strength});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final lit = hole;
    final rounded = lit == null
        ? null
        : RRect.fromRectAndRadius(
            lit,
            const Radius.circular(_TutorialSpotlightState._holeRadius),
          );
    if (rounded != null) path.addRRect(rounded);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = AppColors.base.withAlpha(alphaFor(0.86 * strength)),
    );
    if (rounded != null) {
      canvas.drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.gold.withAlpha(alphaFor(0.7 * strength)),
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.strength != strength;
}
