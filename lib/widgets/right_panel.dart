import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/responsive.dart';
import 'panel/panel_blocks.dart';

/// The third section on wide windows, a solid column of its own like the
/// navigation rail. It holds the pinned note, the countdown, "on this day",
/// the letters and the photo notes, in the order he chose, and scrolls on
/// its own.
class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Responsive.rightPanelWidth,
      decoration: const BoxDecoration(
        color: AppColors.base,
        border: Border(left: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        left: false,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(14, 22, 14, 0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 24),
            child: PanelBlocks(),
          ),
        ),
      ),
    );
  }
}
