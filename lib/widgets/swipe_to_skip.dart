import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Which way a finished swipe should skip.
enum SkipDirection { none, previous, next }

/// Makes its child swipeable like Spotify's mini player: swipe left for the
/// next song, right for the previous one. The old track slides away, the
/// skip happens, and the new track slides in from the other side.
class SwipeToSkip extends StatefulWidget {
  final Widget child;
  final bool canPrevious;
  final bool canNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const SwipeToSkip({
    super.key,
    required this.child,
    required this.canPrevious,
    required this.canNext,
    required this.onPrevious,
    required this.onNext,
  });

  /// A drag counts once it covers this share of the width (and at least
  /// [minDistance]), or when it ends as a quick flick.
  static const double distanceShare = 0.25;
  static const double minDistance = 24;
  static const double flingVelocity = 700;

  /// Pure decision, kept apart from the animation so it can be tested.
  /// [dx] is how far the finger travelled (negative = left); [velocity] is
  /// the horizontal speed at release in px/s.
  static SkipDirection decide({
    required double dx,
    required double velocity,
    required double width,
    required bool canPrevious,
    required bool canNext,
  }) {
    final byDistance = dx.abs() >= math.max(minDistance, width * distanceShare);
    final byFling = velocity.abs() >= flingVelocity &&
        (dx == 0 || dx.sign == velocity.sign);
    if (!byDistance && !byFling) return SkipDirection.none;

    final leftward = byDistance ? dx < 0 : velocity < 0;
    if (leftward) return canNext ? SkipDirection.next : SkipDirection.none;
    return canPrevious ? SkipDirection.previous : SkipDirection.none;
  }

  @override
  State<SwipeToSkip> createState() => _SwipeToSkipState();
}

class _SwipeToSkipState extends State<SwipeToSkip> {
  static const _slideOut = Duration(milliseconds: 110);
  static const _slideIn = Duration(milliseconds: 180);

  /// Dragging towards a side with no song behind it feels heavy.
  static const _resistance = 0.25;

  double _dx = 0;
  double _opacity = 1;
  Duration _duration = Duration.zero; // zero while the finger is down
  bool _busy = false; // the slide-out / slide-in is running

  void _onUpdate(DragUpdateDetails details) {
    if (_busy) return;
    final towardsNext = _dx + details.delta.dx < 0;
    final allowed = towardsNext ? widget.canNext : widget.canPrevious;
    setState(() {
      _duration = Duration.zero;
      _dx += details.delta.dx * (allowed ? 1 : _resistance);
    });
  }

  Future<void> _onEnd(DragEndDetails details, double width) async {
    if (_busy) return;
    final direction = SwipeToSkip.decide(
      dx: _dx,
      velocity: details.primaryVelocity ?? 0,
      width: width,
      canPrevious: widget.canPrevious,
      canNext: widget.canNext,
    );
    if (direction == SkipDirection.none) {
      setState(() {
        _duration = _slideIn;
        _dx = 0;
      });
      return;
    }
    await _commit(direction, width);
  }

  Future<void> _commit(SkipDirection direction, double width) async {
    _busy = true;
    final away = (direction == SkipDirection.next ? -1.0 : 1.0) * width * 0.4;

    // 1. The old track slides off and fades.
    setState(() {
      _duration = _slideOut;
      _dx = away;
      _opacity = 0;
    });
    await Future<void>.delayed(_slideOut);
    if (!mounted) return;

    // 2. Skip, and park the new track just off the opposite side.
    if (direction == SkipDirection.next) {
      widget.onNext();
    } else {
      widget.onPrevious();
    }
    setState(() {
      _duration = Duration.zero;
      _dx = -away;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 3. The new track slides in.
    setState(() {
      _duration = _slideIn;
      _dx = 0;
      _opacity = 1;
    });
    await Future<void>.delayed(_slideIn);
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onUpdate,
          onHorizontalDragEnd: (details) => _onEnd(details, width),
          child: ClipRect(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: _duration,
              child: AnimatedContainer(
                duration: _duration,
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(_dx, 0, 0),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
