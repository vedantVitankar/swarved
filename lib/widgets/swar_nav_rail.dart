import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../tutorial/tutorial_controller.dart';
import 'nav_destinations.dart';
import 'nav_item.dart';

/// The same tabs as a side rail, for tablets and desktop windows.
class SwarNavRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const SwarNavRail({super.key, required this.index, required this.onChanged});

  static const double width = 96;

  @override
  Widget build(BuildContext context) {
    // Keys for the tour's spotlight; null when there is no tour.
    final tutorial = TutorialScope.read(context);
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.base,
        border: Border(right: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 24),
            for (var i = 0; i < swarDestinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: width,
                  child: NavItem(
                    key: tutorial?.navKey(i),
                    destination: swarDestinations[i],
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
