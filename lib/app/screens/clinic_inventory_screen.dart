import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../ui/blocks.dart';

/// Clinic inventory drill-down (manager). Opened from the Low-Stock alert on
/// the manager home screen; defaults to the low-stock filter.
class ClinicInventoryScreen extends StatefulWidget {
  /// Which filter to select on first open: 'all', 'low', or 'out'.
  final String initialFilter;

  const ClinicInventoryScreen({super.key, this.initialFilter = 'low'});

  @override
  State<ClinicInventoryScreen> createState() => _ClinicInventoryScreenState();
}

class _ClinicInventoryScreenState extends State<ClinicInventoryScreen> {
  bool _loading = true;
  String? _error;
  late String _filter = widget.initialFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await context.inventoryService.fetchItems();
    if (!mounted) return;
    setState(() {
      _error = context.inventoryService.error;
      _loading = false;
    });
  }

  void _setFilter(String f) => setState(() => _filter = f);

  List<InventoryItem> _visible() {
    final service = context.inventoryService;
    switch (_filter) {
      case 'low':
        return service.items
            .where((i) => i.isLowStock && !i.isOutOfStock)
            .toList();
      case 'out':
        return service.items.where((i) => i.isOutOfStock).toList();
      default:
        return service.items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DSIconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.textPrimary,
                      size: ds.spacing.md,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  Expanded(
                    child: DSText(
                      t('مخزون العيادة', 'Clinic Inventory'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(child: _body(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, String Function(String, String) t) {
    final ds = DSProvider.of(context);
    if (_loading) return const ShimmerLoading();
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSText(_error!,
                role: DSTextRole.caption, align: TextAlign.center),
            SizedBox(height: ds.spacing.md),
            DSButton(
              label: t('إعادة المحاولة', 'Retry'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final service = context.inventoryService;
    final items = _visible();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary counts.
        Row(
          children: [
            Expanded(
              child: _CountTile(
                label: t('الإجمالي', 'Total'),
                value: '${service.totalItems}',
                color: const Color(0xFF6366F1),
              ),
            ),
            SizedBox(width: ds.spacing.sm),
            Expanded(
              child: _CountTile(
                label: t('منخفض', 'Low'),
                value: '${service.lowStockCount}',
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(width: ds.spacing.sm),
            Expanded(
              child: _CountTile(
                label: t('نفذ', 'Out'),
                value: '${service.outOfStockCount}',
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        SizedBox(height: ds.spacing.md),

        // Filter chips.
        Row(
          children: [
            _FilterChip(
              label: t('الكل', 'All'),
              selected: _filter == 'all',
              onTap: () => _setFilter('all'),
            ),
            SizedBox(width: ds.spacing.sm),
            _FilterChip(
              label: t('منخفض', 'Low'),
              selected: _filter == 'low',
              color: const Color(0xFFF59E0B),
              onTap: () => _setFilter('low'),
            ),
            SizedBox(width: ds.spacing.sm),
            _FilterChip(
              label: t('نفذ', 'Out'),
              selected: _filter == 'out',
              color: const Color(0xFFEF4444),
              onTap: () => _setFilter('out'),
            ),
          ],
        ),
        SizedBox(height: ds.spacing.md),

        Expanded(
          child: items.isEmpty
              ? Center(
                  child: DSText(
                    t('لا أصناف', 'No items'),
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: ds.spacing.sm),
                  itemBuilder: (context, index) =>
                      _ClinicInventoryCard(item: items[index]),
                ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CountTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText(value, role: DSTextRole.headline, color: color),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            label,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final chipColor = color ?? ds.colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md,
          vertical: ds.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? chipColor.withOpacity(0.15) : ds.colors.surface,
          borderRadius: BorderRadius.circular(ds.radii.pill),
          border: Border.all(color: selected ? chipColor : ds.colors.border),
        ),
        child: DSText(
          label,
          role: DSTextRole.label,
          color: selected ? chipColor : ds.colors.textSecondary,
        ),
      ),
    );
  }
}

class _ClinicInventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _ClinicInventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final minQty = item.minQuantity ?? 1;
    final percentage =
        minQty > 0 ? (item.quantity / minQty).clamp(0.0, 1.0) : 1.0;

    Color itemColor;
    String statusLabel;
    LineIconType icon;
    if (item.isOutOfStock) {
      itemColor = const Color(0xFFEF4444);
      statusLabel = t('نفذ', 'Out');
      icon = LineIconType.bell;
    } else if (item.isLowStock) {
      itemColor = const Color(0xFFF59E0B);
      statusLabel = t('منخفض', 'Low');
      icon = LineIconType.heart;
    } else {
      itemColor = const Color(0xFF10B981);
      statusLabel = t('جيد', 'Good');
      icon = LineIconType.chart;
    }

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ds.spacing.xl,
                height: ds.spacing.xl,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: Center(
                  child: DSLineIcon(
                    type: icon,
                    color: itemColor,
                    size: ds.spacing.md,
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(item.name, role: DSTextRole.title, maxLines: 1),
                    SizedBox(height: ds.spacing.xs / 2),
                    Row(
                      children: [
                        DSText(
                          '${item.quantity}',
                          role: DSTextRole.label,
                          color: itemColor,
                        ),
                        if (item.minQuantity != null)
                          DSText(
                            ' / ${item.minQuantity} ${t('الحد الأدنى', 'min')}',
                            role: DSTextRole.caption,
                            color: ds.colors.textSecondary,
                          ),
                        if (item.unit != null) ...[
                          DSText(
                            ' · ${item.unit}',
                            role: DSTextRole.caption,
                            color: ds.colors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              StatusPill(label: statusLabel, color: itemColor),
            ],
          ),
          SizedBox(height: ds.spacing.md),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [itemColor, itemColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
