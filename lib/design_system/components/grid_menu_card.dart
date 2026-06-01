import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_card.dart';
import '../primitives/ds_text.dart';
import 'line_icons.dart';

class GridMenuCard extends StatelessWidget {
  final String title;
  final String caption;
  final LineIconType icon;
  final Color tint;
  final VoidCallback onTap;

  const GridMenuCard({
    super.key,
    required this.title,
    required this.caption,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final iconHolderSize = ds.spacing.xl + ds.spacing.md;
    return GestureDetector(
      onTap: onTap,
      child: DSCard(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        background: ds.colors.surface,
        shadows: ds.shadows.level1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconHolderSize,
              height: iconHolderSize,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                  type: icon,
                  color: tint,
                  size: ds.spacing.md + ds.spacing.sm,
                ),
              ),
            ),
            SizedBox(height: ds.spacing.sm),
            DSText(
              title,
              role: DSTextRole.title,
            ),
            SizedBox(height: ds.spacing.xs),
            DSText(
              caption,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
