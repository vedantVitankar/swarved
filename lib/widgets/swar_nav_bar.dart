import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'nav_destinations.dart';
import 'nav_item.dart';

/// The bottom tab bar for phones and narrow windows.
class SwarNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const SwarNavBar({super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.base,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              for (var i = 0; i < swarDestinations.length; i++)
                Expanded(
                  child: NavItem(
                    destination: swarDestinations[i],
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
