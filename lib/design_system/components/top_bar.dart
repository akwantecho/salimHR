import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_text.dart';
import 'line_icons.dart';

/// Personalized top bar: a user-initials avatar with a time-of-day greeting
/// and the user's (locale-aware) name, plus a notification bell. Flat — no
/// boxed card — so it reads as a lightweight header, not a panel.
class TopBarCustom extends StatelessWidget {
  /// The user's display name (already localized by the caller).
  final String title;

  /// Small line above the name, e.g. a time-of-day greeting.
  final String? subtitle;

  final VoidCallback onNotifications;
  final int notificationCount;

  const TopBarCustom({
    super.key,
    required this.title,
    this.subtitle,
    required this.onNotifications,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _Avatar(),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSubtitle)
                  DSText(
                    subtitle!,
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                    maxLines: 1,
                  ),
                DSText(
                  title,
                  role: DSTextRole.title,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          _BellButton(
            onTap: onNotifications,
            count: notificationCount,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final size = ds.spacing.xl + ds.spacing.sm;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ds.colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: ds.colors.primary.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(ds.spacing.xs),
          child: Image.asset(
            'assets/logo/salimhr bg.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;

  const _BellButton({required this.onTap, required this.count});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: ds.spacing.xl + ds.spacing.sm,
            height: ds.spacing.xl + ds.spacing.sm,
            decoration: BoxDecoration(
              color: ds.colors.surface,
              borderRadius: BorderRadius.circular(ds.radii.large),
              border: Border.all(color: ds.colors.border),
            ),
            child: Center(
              child: DSLineIcon(
                type: LineIconType.bell,
                color: ds.colors.textPrimary,
                size: ds.spacing.lg,
              ),
            ),
          ),
          if (count > 0)
            PositionedDirectional(
              top: -4,
              end: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: ds.colors.background, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
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
    );
  }
}
