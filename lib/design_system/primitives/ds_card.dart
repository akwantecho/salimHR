import 'package:flutter/widgets.dart';

import '../ds_provider.dart';

class DSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? background;
  final double? cornerRadius;
  final List<BoxShadow>? shadows;
  final bool border;

  const DSCard({
    super.key,
    required this.child,
    this.padding,
    this.background,
    this.cornerRadius,
    this.shadows,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? ds.colors.surface,
        borderRadius: BorderRadius.circular(cornerRadius ?? ds.radii.large),
        border: border
            ? Border.all(color: ds.colors.border, width: 1)
            : null,
        boxShadow: shadows ?? ds.shadows.level1,
      ),
      child: Padding(
        padding: padding ??
            EdgeInsetsDirectional.all(
              ds.spacing.md,
            ),
        child: child,
      ),
    );
  }
}
