import 'package:flutter/material.dart';

/// A column whose children rise and fade in one after another. One
/// controller drives all of them, so it costs no timers and stops by itself.
///
/// The number of children is fixed for the life of the widget. With
/// [instant] everything is simply there from the first frame.
class StaggerColumn extends StatefulWidget {
  final List<Widget> children;
  final bool instant;

  /// How long each child waits after the one before it.
  final Duration gap;

  /// How long each child takes to arrive.
  final Duration fade;

  const StaggerColumn({
    super.key,
    required this.children,
    this.instant = false,
    this.gap = const Duration(milliseconds: 180),
    this.fade = const Duration(milliseconds: 520),
  });

  @override
  State<StaggerColumn> createState() => _StaggerColumnState();
}

class _StaggerColumnState extends State<StaggerColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<CurvedAnimation> _curves;

  @override
  void initState() {
    super.initState();
    final count = widget.children.length;
    final gaps = count > 1 ? count - 1 : 0;
    final total = widget.fade + widget.gap * gaps;
    _controller = AnimationController(vsync: this, duration: total);
    _curves = [
      for (var i = 0; i < count; i++)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            widget.gap.inMilliseconds * i / total.inMilliseconds,
            (widget.gap.inMilliseconds * i + widget.fade.inMilliseconds) /
                total.inMilliseconds,
            curve: Curves.easeOut,
          ),
        ),
    ];
    if (widget.instant) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    for (final curve in _curves) {
      curve.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.children.length == _curves.length);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _curves.length; i++)
          FadeTransition(
            opacity: _curves[i],
            child: SlideTransition(
              position: _curves[i].drive(
                Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero),
              ),
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}
