import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'nav_destinations.dart';

/// Icon over label. Cream when selected, faint otherwise.
class NavItem extends StatelessWidget {
  final SwarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textFaint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(destination.label,
                style: AppType.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
