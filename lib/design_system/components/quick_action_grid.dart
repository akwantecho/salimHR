import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_text.dart';
import 'line_icons.dart';

class QuickAction {
  final String label;
  final LineIconType icon;
  final VoidCallback onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// A row of rounded quick-action tiles (default 4-up). Each tile is a soft
/// surface card with a tinted icon chip and a caption. See DESIGN.md → Layout.
class QuickActionGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final int columns;

  const QuickActionGrid({
    super.key,
    required this.actions,
    this.columns = 4,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(width: ds.spacing.sm),
          Expanded(child: _Tile(action: actions[i])),
        ],
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  final QuickAction action;
  const _Tile({required this.action});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: widget.action.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: ds.animation.fast,
        curve: ds.animation.curve,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ds.spacing.xs,
            vertical: ds.spacing.md,
          ),
          decoration: BoxDecoration(
            color: ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(color: ds.colors.border),
            boxShadow: ds.shadows.level1,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ds.spacing.xxl,
                height: ds.spacing.xxl,
                decoration: BoxDecoration(
                  color: ds.colors.accent,
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                alignment: Alignment.center,
                child: DSLineIcon(
                  type: widget.action.icon,
                  color: ds.colors.primary,
                  size: ds.spacing.lg,
                ),
              ),
              SizedBox(height: ds.spacing.sm),
              DSText(
                widget.action.label,
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
                align: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
