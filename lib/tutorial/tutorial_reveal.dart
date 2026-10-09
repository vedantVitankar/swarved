import 'package:flutter/material.dart';
import '../utils/tutorial_timeline.dart';
import 'tutorial_controller.dart';

/// Keeps its child invisible, but still laid out, until the intro lets it
/// appear, then fades it in. [order] sets its turn among the blocks of Home;
/// [note] makes it wait for the home note's own moment instead.
///
/// Built after its moment has passed (a filter switched back on, say), or
/// with no intro at all, it is simply there. So are reduced-motion users.
class TutorialReveal extends StatefulWidget {
  final int order;
  final bool note;
  final Widget child;

  const TutorialReveal({
    super.key,
    this.order = 0,
    this.note = false,
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
    final wait = TutorialTimeline.revealGap * (widget.note ? 0 : widget.order);
    final total = wait + TutorialTimeline.revealFade;
    _controller = AnimationController(vsync: this, duration: total);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        wait.inMilliseconds / total.inMilliseconds,
        1.0,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tutorial = TutorialScope.maybeOf(context);
    final show = tutorial == null ||
        (widget.note ? tutorial.noteVisible : tutorial.blocksVisible);
    final firstLook = _first;
    _first = false;
    if (!show || _shown) return;
    _shown = true;
    if (firstLook || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _controller.value = 1;
    } else {
      _controller.forward();
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
