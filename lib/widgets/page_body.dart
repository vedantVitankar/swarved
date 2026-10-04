import 'package:flutter/material.dart';

/// The frame every tab screen sits in: safe area, scrolling, side padding,
/// and a maximum width so wide Windows windows don't stretch the layout.
class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});

  static const double maxWidth = 640;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
