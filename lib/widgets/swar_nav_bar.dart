import 'package:flutter/material.dart';
import '../content/labels.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// The four-tab bar from the preview: Home, Search, Library, Us.
class SwarNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const SwarNavBar({super.key, required this.index, required this.onChanged});

  static const _tabs = [
    (Icons.home_outlined, Labels.navHome),
    (Icons.search, Labels.navSearch),
    (Icons.library_music_outlined, Labels.navLibrary),
    (Icons.favorite_border, Labels.navUs),
  ];

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
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _tabs[i].$1,
                    label: _tabs[i].$2,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
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
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: AppType.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
