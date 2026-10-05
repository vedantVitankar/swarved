import 'package:flutter/material.dart';
import '../theme/responsive.dart';

/// The frame every tab screen sits in: safe area, scrolling, side padding,
/// and a maximum width so wide windows don't stretch the layout.
class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final side = Responsive.of(width) == ScreenClass.compact ? 16.0 : 24.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(side, 20, side, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Responsive.contentMaxWidth,
            ),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
