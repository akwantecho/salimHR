import 'package:flutter/services.dart';
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

/// Cart-style screen for creating a new inventory request.
///
/// Top half: searchable list of items in the clinic — tap to add to the cart.
/// Bottom panel: the cart (item × qty), with +/- steppers, a notes field,
/// and a "submit" button that posts to `POST /api/inventory/requests`.
class InventoryRequestScreen extends StatefulWidget {
  final VoidCallback onBack;

  const InventoryRequestScreen({super.key, required this.onBack});

  @override
  State<InventoryRequestScreen> createState() => _InventoryRequestScreenState();
}

class _InventoryRequestScreenState extends State<InventoryRequestScreen> {
  bool _isLoading = true;
  bool _submitting = false;
  String? _error;
  String? _successMsg;
  List<InventoryItem> _items = [];
  String _query = '';
  // itemId → requested qty.
  final Map<int, int> _cart = {};
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final svc = context.inventoryService;
      await svc.fetchItems();
      if (!mounted) return;
      _items = svc.items;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<InventoryItem> get _filtered {
    if (_query.trim().isEmpty) return _items;
    final q = _query.toLowerCase().trim();
    return _items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          (i.sku?.toLowerCase().contains(q) ?? false) ||
          (i.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // Categories the user has expanded (dropdown open).
  final Set<String> _openCats = {};

  /// Preferred display order of the storefront sections.
  static const List<String> _categoryOrder = [
    'مواد غذائية',
    'مواد تنظيف',
    'مستلزمات طبية',
    'مستلزمات قرطاسية',
  ];

  bool _isOpen(String cat) => _openCats.contains(cat) || _query.trim().isNotEmpty;

  void _toggleCat(String cat) {
    setState(() {
      if (_openCats.contains(cat)) {
        _openCats.remove(cat);
      } else {
        _openCats.add(cat);
      }
    });
  }

  /// Groups the (filtered) items by category, ordered by [_categoryOrder]
  /// (unknown categories fall to the end, then alphabetical). Items without a
  /// category fall under "أخرى / Other".
  Map<String, List<InventoryItem>> _grouped() {
    final map = <String, List<InventoryItem>>{};
    for (final item in _filtered) {
      final cat = (item.category != null && item.category!.trim().isNotEmpty)
          ? item.category!.trim()
          : tr(context, ar: 'أخرى', en: 'Other');
      map.putIfAbsent(cat, () => []).add(item);
    }

    int rank(String c) {
      final i = _categoryOrder.indexOf(c);
      return i == -1 ? 999 : i;
    }

    final keys = map.keys.toList()
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.compareTo(b);
      });

    return {for (final k in keys) k: map[k]!};
  }

  void _addToCart(InventoryItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
    });
  }

  void _adjust(int itemId, int delta) {
    setState(() {
      final cur = _cart[itemId] ?? 0;
      final next = cur + delta;
      if (next <= 0) {
        _cart.remove(itemId);
      } else {
        _cart[itemId] = next;
      }
    });
  }

  bool get _canSubmit => _cart.isNotEmpty && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _successMsg = null;
    });

    final items = _cart.entries
        .map(
          (e) => <String, int>{
            'inventory_item_id': e.key,
            'requested_qty': e.value,
          },
        )
        .toList();

    try {
      final response = await context.inventoryService.createRequest(
        items: items,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      if (response != null) {
        setState(() {
          _submitting = false;
          _successMsg = tr(
            context,
            ar: 'تم إرسال الطلب بنجاح',
            en: 'Request submitted successfully',
          );
          _cart.clear();
          _notesCtrl.clear();
        });
      } else {
        setState(() {
          _submitting = false;
          _error =
              context.inventoryService.error ??
              tr(context, ar: 'فشل الإرسال', en: 'Submit failed');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
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
          padding: EdgeInsetsDirectional.fromSTEB(
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: t('طلب مخزون جديد', 'New Inventory Request'),
                subtitle: t('اختر المواد المطلوبة', 'Select items you need'),
                onBack: widget.onBack,
              ),
              SizedBox(height: ds.spacing.md),
              if (_successMsg != null)
                _Banner(message: _successMsg!, color: const Color(0xFF10B981)),
              if (_error != null)
                _Banner(message: _error!, color: const Color(0xFFEF4444)),
              if (_isLoading)
                const Expanded(child: ShimmerLoading())
              else
                Expanded(
                  child: Column(
                    children: [
                      _SearchField(controller: _searchCtrl),
                      SizedBox(height: ds.spacing.sm),
                      Expanded(
                        child: _filtered.isEmpty
                            ? _Empty(
                                message: t('لا توجد مواد', 'No items'),
                                icon: LineIconType.search,
                              )
                            : ListView(
                                children: [
                                  for (final entry in _grouped().entries) ...[
                                    _CategoryHeader(
                                      title: entry.key,
                                      count: entry.value.length,
                                      expanded: _isOpen(entry.key),
                                      onTap: () => _toggleCat(entry.key),
                                    ),
                                    if (_isOpen(entry.key))
                                      for (final item in entry.value)
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(
                                            bottom: ds.spacing.xs,
                                          ),
                                          child: _ItemRow(
                                            item: item,
                                            inCartQty: _cart[item.id] ?? 0,
                                            onAdd: () => _addToCart(item),
                                            onInc: () => _adjust(item.id, 1),
                                            onDec: () => _adjust(item.id, -1),
                                          ),
                                        ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              if (_cart.isNotEmpty) ...[
                SizedBox(height: ds.spacing.sm),
                _CartSummary(
                  cartCount: _cart.values.fold<int>(0, (a, b) => a + b),
                ),
                SizedBox(height: ds.spacing.sm),
                _NotesField(controller: _notesCtrl),
                SizedBox(height: ds.spacing.sm),
                DSButton(
                  label: _submitting
                      ? t('جاري الإرسال...', 'Submitting...')
                      : t('إرسال الطلب', 'Submit Request'),
                  onPressed: _canSubmit ? _submit : null,
                  variant: DSButtonVariant.primary,
                  size: DSButtonSize.large,
                  expanded: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Row(
      children: [
        DSIconButton(
          onPressed: onBack,
          icon: DSLineIcon(
            type: LineIconType.arrowBack,
            color: ds.colors.textPrimary,
            size: ds.spacing.md,
          ),
        ),
        SizedBox(width: ds.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(title, role: DSTextRole.headline),
              SizedBox(height: 2),
              DSText(
                subtitle,
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;

  const _Banner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
      child: Container(
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ds.radii.medium),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: DSText(
          message,
          role: DSTextRole.body,
          color: color,
          maxLines: 3,
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        children: [
          DSLineIcon(
            type: LineIconType.search,
            color: ds.colors.textMuted,
            size: ds.spacing.md,
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => Stack(
                children: [
                  if (widget.controller.text.isEmpty)
                    DSText(
                      t('ابحث عن مادة...', 'Search items...'),
                      role: DSTextRole.body,
                      color: ds.colors.textMuted,
                    ),
                  EditableText(
                    controller: widget.controller,
                    focusNode: _focus,
                    style: ds.typography.body.copyWith(
                      color: ds.colors.textPrimary,
                    ),
                    cursorColor: ds.colors.primary,
                    backgroundCursorColor: ds.colors.textMuted,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Storefront section header — a tappable dropdown showing the category name,
/// its item count, and a chevron that flips when the section is expanded.
class _CategoryHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _CategoryHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ds.spacing.md,
            vertical: ds.spacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: expanded
                ? ds.colors.primary.withValues(alpha: 0.08)
                : ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.large),
            border: Border.all(
              color: expanded
                  ? ds.colors.primary.withValues(alpha: 0.4)
                  : ds.colors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: ds.spacing.xs,
                height: ds.spacing.md,
                decoration: BoxDecoration(
                  color: ds.colors.primary,
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(child: DSText(title, role: DSTextRole.title)),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
                child: DSText(
                  '$count',
                  role: DSTextRole.caption,
                  color: ds.colors.primary,
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: DSText('⌄', role: DSTextRole.title, color: ds.colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InventoryItem item;
  final int inCartQty;
  final VoidCallback onAdd;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _ItemRow({
    required this.item,
    required this.inCartQty,
    required this.onAdd,
    required this.onInc,
    required this.onDec,
  });

  Color _stockColor() {
    if (item.isOutOfStock) return const Color(0xFFEF4444);
    if (item.isLowStock) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final stockColor = _stockColor();

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            alignment: Alignment.center,
            child: DSText(
              '${item.quantity}',
              role: DSTextRole.title,
              color: stockColor,
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(item.name, role: DSTextRole.title, maxLines: 1),
                SizedBox(height: 2),
                DSText(
                  '${item.sku ?? '—'} · ${item.unit ?? t('وحدة', 'unit')}',
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          if (inCartQty == 0)
            DSButton(
              label: t('إضافة', 'Add'),
              variant: DSButtonVariant.ghost,
              onPressed: onAdd,
            )
          else
            Row(
              children: [
                _StepBtn(label: '-', onTap: onDec),
                SizedBox(width: ds.spacing.xs),
                Container(
                  constraints: BoxConstraints(minWidth: ds.spacing.xl),
                  alignment: Alignment.center,
                  child: DSText('$inCartQty', role: DSTextRole.title),
                ),
                SizedBox(width: ds.spacing.xs),
                _StepBtn(label: '+', onTap: onInc),
              ],
            ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ds.spacing.xl,
        height: ds.spacing.xl,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ds.colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: ds.colors.primary.withValues(alpha: 0.3)),
        ),
        child: DSText(label, role: DSTextRole.title, color: ds.colors.primary),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int cartCount;

  const _CartSummary({required this.cartCount});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: ds.colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DSText(
              t('عناصر في الطلب', 'Items in request'),
              role: DSTextRole.label,
              color: ds.colors.textSecondary,
            ),
          ),
          DSText(
            '$cartCount',
            role: DSTextRole.title,
            color: ds.colors.primary,
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final TextEditingController controller;

  const _NotesField({required this.controller});

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => Stack(
          children: [
            if (widget.controller.text.isEmpty)
              DSText(
                t('ملاحظات (اختياري)', 'Notes (optional)'),
                role: DSTextRole.body,
                color: ds.colors.textMuted,
              ),
            EditableText(
              controller: widget.controller,
              focusNode: _focus,
              style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
              cursorColor: ds.colors.primary,
              backgroundCursorColor: ds.colors.textMuted,
              minLines: 2,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  final LineIconType icon;

  const _Empty({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DSLineIcon(
            type: icon,
            color: ds.colors.textMuted,
            size: ds.spacing.xl,
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(
            message,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}
