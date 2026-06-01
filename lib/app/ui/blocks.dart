import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';

// ==================== SHIMMER LOADING ====================

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards row
          Row(
            children: [
              Expanded(child: _ShimmerBox(height: 80, radius: ds.radii.large, phase: _controller.value)),
              SizedBox(width: ds.spacing.sm),
              Expanded(child: _ShimmerBox(height: 80, radius: ds.radii.large, phase: _controller.value)),
            ],
          ),
          SizedBox(height: ds.spacing.lg),
          // Section header
          _ShimmerBox(height: 14, width: 120, radius: ds.radii.small, phase: _controller.value),
          SizedBox(height: ds.spacing.md),
          // Card rows
          _ShimmerBox(height: 72, radius: ds.radii.large, phase: _controller.value),
          SizedBox(height: ds.spacing.sm),
          _ShimmerBox(height: 72, radius: ds.radii.large, phase: _controller.value),
          SizedBox(height: ds.spacing.sm),
          _ShimmerBox(height: 72, radius: ds.radii.large, phase: _controller.value),
          SizedBox(height: ds.spacing.lg),
          // Another section
          _ShimmerBox(height: 14, width: 100, radius: ds.radii.small, phase: _controller.value),
          SizedBox(height: ds.spacing.md),
          _ShimmerBox(height: 72, radius: ds.radii.large, phase: _controller.value),
          SizedBox(height: ds.spacing.sm),
          _ShimmerBox(height: 72, radius: ds.radii.large, phase: _controller.value),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  final double phase;

  const _ShimmerBox({
    required this.height,
    this.width,
    required this.radius,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final baseColor = ds.colors.surfaceAlt;
    final highlightColor = ds.colors.surface;
    final t = (math.sin(phase * 2 * math.pi) + 1) / 2;
    final color = Color.lerp(baseColor, highlightColor, t)!;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: DSText(
              title,
              role: DSTextRole.title,
            ),
          ),
          if (actionLabel != null)
            DSButton(
              label: actionLabel!,
              variant: DSButtonVariant.ghost,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
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
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(ds.radii.pill),
      ),
      child: DSText(
        label,
        role: DSTextRole.caption,
        color: color,
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? caption;
  final Color? accent;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.caption,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final accentColor = accent ?? ds.colors.primary;
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label: title, color: accentColor),
          SizedBox(height: ds.spacing.sm),
          DSText(value, role: DSTextRole.display),
          if (caption != null) ...[
            SizedBox(height: ds.spacing.xs),
            DSText(
              caption!,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class ShortcutCard extends StatelessWidget {
  final String label;
  final LineIconType icon;
  final VoidCallback? onTap;

  const ShortcutCard({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final size = ds.spacing.xl + ds.spacing.sm;
    return GestureDetector(
      onTap: onTap,
      child: DSCard(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        child: Row(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: ds.colors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                  type: icon,
                  color: ds.colors.textPrimary,
                  size: ds.spacing.md,
                ),
              ),
            ),
            SizedBox(width: ds.spacing.md),
            DSText(label, role: DSTextRole.title),
          ],
        ),
      ),
    );
  }
}

class RequestTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Widget? trailing;

  const RequestTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(title, role: DSTextRole.title),
                SizedBox(height: ds.spacing.xs),
                DSText(
                  subtitle,
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
                SizedBox(height: ds.spacing.sm),
                StatusPill(label: status, color: statusColor),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: ds.spacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class SliverSeparatedList extends StatelessWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final double spacing;

  const SliverSeparatedList({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index.isOdd) {
            return SizedBox(height: spacing);
          }
          final itemIndex = index ~/ 2;
          return itemBuilder(context, itemIndex);
        },
        childCount: itemCount * 2 - 1,
      ),
    );
  }
}
