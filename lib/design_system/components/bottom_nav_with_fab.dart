import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_text.dart';
import 'bottom_nav.dart';
import 'line_icons.dart';

/// Bottom navigation with a center FAB-style "add" button.
///
/// Layout: [items[0]] [items[1]] [+ FAB] [items[2]] [items[3]]
///
/// The 4 items map to indices 0..3 in [onSelect]. The FAB triggers a separate
/// [onAddTap] callback and does not change [currentIndex]. The widget asserts
/// exactly 4 items.
class BottomNavWithFab extends StatelessWidget {
  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddTap;
  final Color? fabColor;

  const BottomNavWithFab({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onAddTap,
    this.fabColor,
  }) : assert(items.length == 4, 'BottomNavWithFab requires exactly 4 items');

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final barHeight = ds.spacing.xl * 3;
    final fabSize = ds.spacing.xl * 2.4;
    final fabAccent = fabColor ?? ds.colors.primary;

    // The bar itself + the FAB protruding above need a SizedBox that includes
    // both heights so the FAB isn't clipped by the parent's tight constraints.
    final stackHeight = barHeight + fabSize * 0.45;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          // Bar
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: ds.colors.surface,
                borderRadius: BorderRadius.circular(ds.radii.xLarge),
                boxShadow: [
                  BoxShadow(
                    color: ds.colors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: ds.colors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: ds.spacing.md,
                vertical: ds.spacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _SideNavItem(
                      item: items[0],
                      colorIndex: 0,
                      isSelected: currentIndex == 0,
                      onTap: () => onSelect(0),
                    ),
                  ),
                  Expanded(
                    child: _SideNavItem(
                      item: items[1],
                      colorIndex: 1,
                      isSelected: currentIndex == 1,
                      onTap: () => onSelect(1),
                    ),
                  ),
                  // Reserve space under the FAB so labels don't overlap.
                  SizedBox(width: fabSize * 0.9),
                  Expanded(
                    child: _SideNavItem(
                      item: items[2],
                      colorIndex: 2,
                      isSelected: currentIndex == 2,
                      onTap: () => onSelect(2),
                    ),
                  ),
                  Expanded(
                    child: _SideNavItem(
                      item: items[3],
                      colorIndex: 3,
                      isSelected: currentIndex == 3,
                      onTap: () => onSelect(3),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center FAB
          PositionedDirectional(
            bottom: barHeight - fabSize * 0.55,
            child: _CenterFab(
              size: fabSize,
              color: fabAccent,
              onTap: onAddTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final BottomNavItem item;
  final int colorIndex;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.item,
    required this.colorIndex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);

    const accentColors = [
      Color(0xFF6366F1), // Indigo - Home
      Color(0xFF10B981), // Emerald - Sessions
      Color(0xFFF59E0B), // Amber - Attendance
      Color(0xFF8B5CF6), // Violet - Profile
    ];

    final accentColor = accentColors[colorIndex % accentColors.length];
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
            AnimatedContainer(
              duration: ds.animation.fast,
              curve: ds.animation.curve,
              padding: EdgeInsetsDirectional.all(ds.spacing.xs),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: DSLineIcon(
                type: item.icon,
                color: color,
                size: ds.spacing.lg,
              ),
            ),
            SizedBox(height: ds.spacing.xs / 2),
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

class _CenterFab extends StatefulWidget {
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _CenterFab({
    required this.size,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final scale = _pressed ? 0.92 : 1.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: ds.animation.fast,
        curve: ds.animation.curve,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.color,
                Color.lerp(widget.color, const Color(0xFF000000), 0.18)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Center(
            child: DSText(
              '+',
              role: DSTextRole.display,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
