import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import 'line_icons.dart';

class BottomNavItem {
  final String label;
  final LineIconType icon;

  const BottomNavItem({
    required this.label,
    required this.icon,
  });
}

class BottomNavigationCustom extends StatelessWidget {
  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const BottomNavigationCustom({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final barHeight = ds.spacing.xl * 2.75;
    return SizedBox(
      height: barHeight,
      child: Container(
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius: BorderRadius.circular(ds.radii.pill),
          boxShadow: [
            BoxShadow(
              color: ds.colors.primary.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: ds.colors.border.withOpacity(0.6),
            width: 1,
          ),
        ),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavItem(
                item: items[i],
                isSelected: i == currentIndex,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

/// A pill nav item: when selected it fills with the brand primary and reveals
/// its label; when idle it collapses to an icon only. Matches DESIGN.md.
class _NavItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final onFill = ds.colors.surface;
    final iconColor = isSelected ? onFill : ds.colors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: ds.animation.normal,
        curve: ds.animation.curve,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: isSelected ? ds.spacing.base : ds.spacing.md,
          vertical: ds.spacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? ds.colors.primary : null,
          borderRadius: BorderRadius.circular(ds.radii.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ds.colors.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSLineIcon(
              type: item.icon,
              color: iconColor,
              size: ds.spacing.lg,
            ),
            AnimatedSize(
              duration: ds.animation.normal,
              curve: ds.animation.curve,
              child: isSelected
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(start: ds.spacing.sm),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.label.copyWith(color: onFill),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
