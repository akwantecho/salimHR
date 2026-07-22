import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_text.dart';
import 'line_icons.dart';

class TopBarCustom extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onNotifications;
  final int notificationCount;

  const TopBarCustom({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onNotifications,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [ds.colors.surface, ds.colors.surface],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: ds.colors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: ds.colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BrandMark(),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DSText(title, role: DSTextRole.headline),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  subtitle,
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ActionButton(
                icon: LineIconType.bell,
                onTap: onNotifications,
                color: const Color(0xFFF59E0B),
              ),
              if (notificationCount > 0)
                PositionedDirectional(
                  top: -4,
                  end: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        notificationCount.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFFFFFF),
                          fontFamily: ds.typography.caption.fontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final LineIconType icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ds.spacing.xxl + ds.spacing.md,
        height: ds.spacing.xxl + ds.spacing.md,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: DSLineIcon(type: icon, color: color, size: ds.spacing.lg),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final brandSize = ds.spacing.xl + ds.spacing.sm;
    return Container(
      width: brandSize,
      height: brandSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [ds.colors.primary, ds.colors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(ds.radii.large),
        boxShadow: [
          BoxShadow(
            color: ds.colors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: DSLineIcon(
          type: LineIconType.heart,
          color: const Color(0xFFFFFFFF),
          size: ds.spacing.lg,
        ),
      ),
    );
  }
}
