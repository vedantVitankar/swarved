import 'package:flutter/material.dart';
import '../utils/tutorial_timeline.dart';
import 'tutorial_controller.dart';

/// Which moment of the tutorial lets a block appear.
enum TutorialPart {
  /// The song of the day's card, which comes first when there is a
  /// tutorial song.
  song,

  /// Everything else on Home, which follows once she has pressed play.
  rest,

  /// The home note, which waits for the end of the tutorial.
  note,
}

/// Keeps its child invisible, but still laid out, until the tutorial lets it
/// appear, then fades it in. [part] says which moment that is, and [order]
/// sets its turn among the blocks that appear at the same moment.
///
/// Built after its moment has passed (a filter switched back on, say), or
/// with no intro at all, it is simply there. So are reduced-motion users.
class TutorialReveal extends StatefulWidget {
  final TutorialPart part;
  final int order;
  final Widget child;

  const TutorialReveal({
    super.key,
    this.part = TutorialPart.rest,
    this.order = 0,
    required this.child,
  });

  @override
  State<TutorialReveal> createState() => _TutorialRevealState();
}

class _TutorialRevealState extends State<TutorialReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _opacity;
  bool _first = true;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: TutorialTimeline.revealFade,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  bool _mayShow(TutorialController tutorial) => switch (widget.part) {
        TutorialPart.song => tutorial.songVisible,
        TutorialPart.rest => tutorial.restVisible,
        TutorialPart.note => tutorial.noteVisible,
      };

  /// Waits for its turn within the fade: [order] gaps, then the fade itself.
  void _fadeIn() {
    final wait = TutorialTimeline.revealGap *
        (widget.part == TutorialPart.note ? 0 : widget.order);
    final total = wait + TutorialTimeline.revealFade;
    _controller.duration = total;
    _opacity.curve = Interval(
      wait.inMilliseconds / total.inMilliseconds,
      1.0,
      curve: Curves.easeOut,
    );
    _controller.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tutorial = TutorialScope.maybeOf(context);
    final show = tutorial == null || _mayShow(tutorial);
    final firstLook = _first;
    _first = false;
    if (!show || _shown) return;
    _shown = true;
    if (firstLook || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _controller.value = 1;
    } else {
      _fadeIn();
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
