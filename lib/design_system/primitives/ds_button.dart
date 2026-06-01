import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import 'ds_text.dart';

enum DSButtonVariant { primary, ghost, pill }
enum DSButtonSize { regular, large }

class DSButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final DSButtonVariant variant;
  final DSButtonSize size;
  final Widget? leading;
  final bool expanded;

  const DSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DSButtonVariant.primary,
    this.size = DSButtonSize.regular,
    this.leading,
    this.expanded = false,
  });

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _pressed = true);
  }

  void _handleTapCancel() {
    setState(() => _pressed = false);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final bool enabled = widget.onPressed != null;

    Color background;
    Color borderColor = ds.colors.border;
    Color textColor = ds.colors.textPrimary;

    switch (widget.variant) {
      case DSButtonVariant.primary:
        background = ds.colors.primary;
        textColor = ds.colors.surface;
        borderColor = ds.colors.primary.withOpacity(0.6);
        break;
      case DSButtonVariant.ghost:
        background = ds.colors.surface;
        textColor = ds.colors.textPrimary;
        borderColor = ds.colors.border;
        break;
      case DSButtonVariant.pill:
        background = ds.colors.accent;
        textColor = ds.colors.textPrimary;
        borderColor = ds.colors.accentMuted;
        break;
    }

    if (!enabled) {
      background = background.withOpacity(ds.opacity.disabled);
      textColor = textColor.withOpacity(ds.opacity.muted);
    } else if (_pressed) {
      background = Color.lerp(background, ds.colors.textPrimary, 0.05)!;
    }

    final EdgeInsetsGeometry padding =
        widget.size == DSButtonSize.large
            ? EdgeInsetsDirectional.symmetric(
                horizontal: ds.spacing.xl,
                vertical: ds.spacing.md,
              )
            : EdgeInsetsDirectional.symmetric(
                horizontal: ds.spacing.lg,
                vertical: ds.spacing.sm,
              );

    final radius =
        widget.variant == DSButtonVariant.pill ? ds.radii.pill : ds.radii.large;

    final buttonChild = Row(
      mainAxisSize:
          widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: ds.textDirection,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          SizedBox(width: ds.spacing.sm),
        ],
        DSText(
          widget.label,
          role: DSTextRole.label,
          color: textColor,
          align: TextAlign.center,
        ),
      ],
    );

    return AnimatedContainer(
      duration: ds.animation.fast,
      curve: ds.animation.curve,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: widget.variant == DSButtonVariant.ghost
            ? ds.shadows.level1
            : ds.shadows.level2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: GestureDetector(
          onTapDown: enabled ? _handleTapDown : null,
          onTapUp: enabled ? _handleTapUp : null,
          onTapCancel: _handleTapCancel,
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: padding,
            child: buttonChild,
          ),
        ),
      ),
    );
  }
}

class DSIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Color? background;
  final EdgeInsetsGeometry? padding;

  const DSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final bg = background ?? ds.colors.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: ds.shadows.level1,
      ),
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: padding ??
              EdgeInsetsDirectional.all(
                ds.spacing.sm,
              ),
          child: icon,
        ),
      ),
    );
  }
}

class DSBadge extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? textColor;

  const DSBadge({
    super.key,
    required this.label,
    this.background,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.sm,
        vertical: ds.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: background ?? ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.pill),
      ),
      child: DSText(
        label,
        role: DSTextRole.caption,
        color: textColor ?? ds.colors.textSecondary,
      ),
    );
  }
}

class DSDivider extends StatelessWidget {
  final double thickness;
  final Color? color;

  const DSDivider({super.key, this.thickness = 1, this.color});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      height: thickness,
      color: color ?? ds.colors.border,
    );
  }
}
