import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_text.dart';

/// Gradient hero card for the top of a home screen — the day's headline metric.
///
/// Fills with a primary → primary-deep gradient (deep derived from primary,
/// matching the FAB treatment). Shows a quiet [label], a large tabular [value],
/// and an optional [footer] (e.g. a day strip). See DESIGN.md → Layout.
class FeaturedCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? footer;

  const FeaturedCard({
    super.key,
    required this.label,
    required this.value,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final primary = ds.colors.primary;
    final deep = Color.lerp(primary, const Color(0xFF000000), 0.22)!;
    final onPrimary = ds.colors.surface;

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.base),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [primary, deep],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.38),
            blurRadius: 26,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DSText(
            label,
            role: DSTextRole.caption,
            color: onPrimary.withOpacity(0.9),
          ),
          SizedBox(height: ds.spacing.xs),
          Text(
            value,
            textDirection: ds.textDirection,
            style: ds.typography.headline.copyWith(
              color: onPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (footer != null) ...[
            SizedBox(height: ds.spacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
