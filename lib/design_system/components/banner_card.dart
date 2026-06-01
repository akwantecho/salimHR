import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_button.dart';
import '../primitives/ds_card.dart';
import '../primitives/ds_text.dart';

class BannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget? illustration;

  const BannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.only(
        start: ds.spacing.lg,
        end: ds.spacing.lg,
        top: ds.spacing.lg,
        bottom: ds.spacing.md,
      ),
      background: ds.colors.surface,
      shadows: ds.shadows.level2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              ds.colors.surface,
              ds.colors.primary.withOpacity(0.10),
              ds.colors.secondary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(ds.radii.large),
        ),
        child: Stack(
          children: [
            if (illustration != null)
              PositionedDirectional(
                end: 0,
                bottom: 0,
                top: 0,
                child: SizedBox(
                  width: ds.spacing.xl * 3,
                  child: illustration,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  title,
                  role: DSTextRole.display,
                ),
                SizedBox(height: ds.spacing.sm),
                DSText(
                  subtitle,
                  role: DSTextRole.body,
                  color: ds.colors.textSecondary,
                ),
                SizedBox(height: ds.spacing.md),
                DSButton(
                  label: actionLabel,
                  variant: DSButtonVariant.pill,
                  size: DSButtonSize.large,
                  onPressed: onAction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
