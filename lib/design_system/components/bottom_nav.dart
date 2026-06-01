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
    final barHeight = ds.spacing.xl * 3;
    return SizedBox(
      height: barHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
            colors: [
              ds.colors.surface,
              ds.colors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(ds.radii.xLarge),
          boxShadow: [
            BoxShadow(
              color: ds.colors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: ds.colors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md,
          vertical: ds.spacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  item: items[i],
                  index: i,
                  isSelected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavItem item;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);

    // Different colors for each tab when selected
    final accentColors = [
      const Color(0xFF6366F1), // Indigo - Home
      const Color(0xFF10B981), // Emerald - Tab 2
      const Color(0xFFF59E0B), // Amber - Tab 3
      const Color(0xFF8B5CF6), // Violet - Profile
    ];

    final accentColor = accentColors[index % accentColors.length];
    final color = isSelected ? accentColor : ds.colors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: ds.animation.fast,
        curve: ds.animation.curve,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.xs,
          vertical: ds.spacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with background
            AnimatedContainer(
              duration: ds.animation.fast,
              curve: ds.animation.curve,
              padding: EdgeInsetsDirectional.all(ds.spacing.xs),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.15) : null,
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: DSLineIcon(
                type: item.icon,
                color: color,
                size: ds.spacing.lg,
              ),
            ),
            SizedBox(height: ds.spacing.xs / 2),
            // Label
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: ds.animation.fast,
                style: ds.typography.caption.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
