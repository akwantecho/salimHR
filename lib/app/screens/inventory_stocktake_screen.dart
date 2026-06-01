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

/// Physical-count screen (جرد المخزون).
///
/// Flow:
///   1. On open, lazily creates an in-progress stocktake session.
///   2. Lists all inventory items; each row shows system qty (read-only) and
///      an input for the user's physical count.
///   3. Every blur on a count input saves that line individually (variance
///      stays accurate per item).
///   4. "Finalize" button locks the session and applies the variance to
///      stock as an adjustment movement.
///   5. "Cancel" abandons the session without touching stock.
class InventoryStocktakeScreen extends StatefulWidget {
  final VoidCallback onBack;

  const InventoryStocktakeScreen({super.key, required this.onBack});

  @override
  State<InventoryStocktakeScreen> createState() =>
      _InventoryStocktakeScreenState();
}

class _InventoryStocktakeScreenState extends State<InventoryStocktakeScreen> {
  bool _isLoading = true;
  bool _finalizing = false;
  String? _error;
  String? _flash;
  Color _flashColor = const Color(0xFF10B981);

  int? _stocktakeId;
  List<InventoryItem> _items = [];
  String _query = '';

  // itemId → physical count (as entered)
  final Map<int, String> _counts = {};
  // itemId → "saved" flag (turned on after server confirms each line)
  final Set<int> _savedItemIds = {};
  final Set<int> _inFlightItemIds = {};

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final svc = context.inventoryService;
      await svc.fetchItems();
      if (!mounted) return;
      _items = svc.items;

      final id = await svc.openStocktake();
      if (!mounted) return;
      if (id == null) {
        setState(() {
          _isLoading = false;
          _error = svc.error ??
              tr(context,
                  ar: 'تعذّر بدء جلسة الجرد', en: 'Could not open stocktake');
        });
        return;
      }
      _stocktakeId = id;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
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

  void _showFlash(String message, Color color) {
    setState(() {
      _flash = message;
      _flashColor = color;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _flash = null);
    });
  }

  Future<void> _saveLine(InventoryItem item, String rawValue) async {
    if (_stocktakeId == null) return;
    final cleaned = rawValue.trim();
    if (cleaned.isEmpty) return;
    final parsed = double.tryParse(cleaned);
    if (parsed == null || parsed < 0) {
      _showFlash(
        tr(context, ar: 'قيمة غير صالحة', en: 'Invalid number'),
        const Color(0xFFEF4444),
      );
      return;
    }

    setState(() => _inFlightItemIds.add(item.id));
    final ok = await context.inventoryService.saveStocktakeItem(
      stocktakeId: _stocktakeId!,
      inventoryItemId: item.id,
      physicalQuantity: parsed,
    );
    if (!mounted) return;
    setState(() {
      _inFlightItemIds.remove(item.id);
      if (ok) {
        _savedItemIds.add(item.id);
        _counts[item.id] = parsed.toString();
      } else {
        _showFlash(
          context.inventoryService.error ??
              tr(context, ar: 'فشل حفظ السطر', en: 'Failed to save line'),
          const Color(0xFFEF4444),
        );
      }
    });
  }

  Future<void> _finalize() async {
    if (_stocktakeId == null) return;
    if (_savedItemIds.isEmpty) {
      _showFlash(
        tr(context, ar: 'لم يتم عدّ أي مادة', en: 'No items counted yet'),
        const Color(0xFFEF4444),
      );
      return;
    }

    final confirm = await _confirmDialog(
      title: tr(context, ar: 'تأكيد الإنهاء', en: 'Finalize stocktake?'),
      body: tr(
        context,
        ar:
            'سيتم تعديل المخزون لتطابق الأعداد المُسجّلة. هذا الإجراء غير قابل للتراجع.',
        en:
            'Stock will be adjusted to match counted values. This cannot be undone.',
      ),
    );
    if (!confirm) return;

    setState(() => _finalizing = true);
    final svc = context.inventoryService;
    final ok = await svc.finalizeStocktake(_stocktakeId!);
    if (!mounted) return;
    setState(() => _finalizing = false);

    if (ok) {
      _showFlash(
        tr(context, ar: 'تم إنهاء الجرد', en: 'Stocktake finalized'),
        const Color(0xFF10B981),
      );
      // Wait a tick so the user sees the success banner, then close.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) widget.onBack();
      });
    } else {
      _showFlash(
        svc.error ?? tr(context, ar: 'فشل الإنهاء', en: 'Finalize failed'),
        const Color(0xFFEF4444),
      );
    }
  }

  Future<void> _cancelSession() async {
    if (_stocktakeId == null) {
      widget.onBack();
      return;
    }
    final svc = context.inventoryService;
    final confirm = await _confirmDialog(
      title: tr(context, ar: 'إلغاء الجلسة؟', en: 'Cancel session?'),
      body: tr(
        context,
        ar: 'ستُلغى جلسة الجرد ولن تؤثّر على المخزون.',
        en: 'Stocktake will be discarded with no effect on stock.',
      ),
    );
    if (!confirm) return;
    await svc.cancelStocktake(_stocktakeId!);
    if (mounted) widget.onBack();
  }

  Future<bool> _confirmDialog({
    required String title,
    required String body,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0xFF000000).withOpacity(0.45),
        pageBuilder: (ctx, _, _) => _ConfirmDialog(title: title, body: body),
      ),
    );
    return result ?? false;
  }

  int get _counted => _savedItemIds.length;
  int get _total => _items.length;

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
                title: t('جرد المخزون', 'Stocktake'),
                subtitle: t(
                  'سجّل العدد الفعلي لكل مادة',
                  'Enter the physical count for each item',
                ),
                onBack: _cancelSession,
              ),
              SizedBox(height: ds.spacing.md),
              if (_flash != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                  child: Container(
                    padding: EdgeInsetsDirectional.all(ds.spacing.md),
                    decoration: BoxDecoration(
                      color: _flashColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                      border: Border.all(color: _flashColor.withOpacity(0.4)),
                    ),
                    child: DSText(
                      _flash!,
                      role: DSTextRole.body,
                      color: _flashColor,
                      maxLines: 3,
                    ),
                  ),
                ),
              if (_isLoading)
                const Expanded(child: ShimmerLoading())
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: DSText(
                      _error!,
                      role: DSTextRole.body,
                      color: const Color(0xFFEF4444),
                      maxLines: 4,
                    ),
                  ),
                )
              else ...[
                _ProgressBanner(counted: _counted, total: _total),
                SizedBox(height: ds.spacing.sm),
                _SearchField(controller: _searchCtrl),
                SizedBox(height: ds.spacing.sm),
                Expanded(
                  child: _filtered.isEmpty
                      ? _Empty(
                          message: t('لا توجد مواد', 'No items'),
                          icon: LineIconType.search,
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) =>
                              SizedBox(height: ds.spacing.xs),
                          itemBuilder: (context, i) {
                            final item = _filtered[i];
                            return _CountRow(
                              item: item,
                              savedValue: _counts[item.id],
                              isSaved: _savedItemIds.contains(item.id),
                              isInFlight: _inFlightItemIds.contains(item.id),
                              onSubmit: (value) => _saveLine(item, value),
                            );
                          },
                        ),
                ),
                SizedBox(height: ds.spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DSButton(
                        label: t('إلغاء', 'Cancel'),
                        variant: DSButtonVariant.ghost,
                        onPressed: _cancelSession,
                        expanded: true,
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      flex: 2,
                      child: DSButton(
                        label: _finalizing
                            ? t('جاري الإنهاء...', 'Finalizing...')
                            : t('إنهاء الجرد', 'Finalize'),
                        onPressed: _finalizing ? null : _finalize,
                        variant: DSButtonVariant.primary,
                        size: DSButtonSize.large,
                        expanded: true,
                      ),
                    ),
                  ],
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
              DSText(subtitle,
                  role: DSTextRole.caption, color: ds.colors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int counted;
  final int total;

  const _ProgressBanner({required this.counted, required this.total});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final ratio = total == 0 ? 0.0 : counted / total;
    final color = const Color(0xFF6366F1);

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(
                  t('تقدم الجرد', 'Stocktake progress'),
                  role: DSTextRole.label,
                  color: ds.colors.textSecondary,
                ),
              ),
              DSText(
                '$counted / $total',
                role: DSTextRole.title,
                color: color,
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
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
                    style: ds.typography.body
                        .copyWith(color: ds.colors.textPrimary),
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

class _CountRow extends StatefulWidget {
  final InventoryItem item;
  final String? savedValue;
  final bool isSaved;
  final bool isInFlight;
  final ValueChanged<String> onSubmit;

  const _CountRow({
    required this.item,
    required this.savedValue,
    required this.isSaved,
    required this.isInFlight,
    required this.onSubmit,
  });

  @override
  State<_CountRow> createState() => _CountRowState();
}

class _CountRowState extends State<_CountRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.savedValue ?? '');
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Save on blur if the value is non-empty and differs from the saved one.
    if (!_focus.hasFocus) {
      final current = _ctrl.text.trim();
      if (current.isNotEmpty && current != (widget.savedValue ?? '')) {
        widget.onSubmit(current);
      }
    }
  }

  double? get _physical => double.tryParse(_ctrl.text.trim());
  double get _system => widget.item.quantity.toDouble();
  double? get _variance => _physical == null ? null : _physical! - _system;

  Color _badgeColor() {
    if (widget.isInFlight) return const Color(0xFFF59E0B);
    if (!widget.isSaved) return const Color(0xFF94A3B8);
    final v = _variance;
    if (v == null || v.abs() < 0.001) return const Color(0xFF10B981);
    return v > 0 ? const Color(0xFF6366F1) : const Color(0xFFEF4444);
  }

  String _badgeLabel(BuildContext context) {
    if (widget.isInFlight) return tr(context, ar: 'حفظ...', en: 'Saving...');
    if (!widget.isSaved) return tr(context, ar: 'بانتظار', en: 'Pending');
    final v = _variance;
    if (v == null || v.abs() < 0.001) return tr(context, ar: 'مطابق', en: 'Match');
    return v > 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final badgeColor = _badgeColor();

    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(widget.item.name,
                        role: DSTextRole.title, maxLines: 1),
                    SizedBox(height: 2),
                    DSText(
                      '${widget.item.sku ?? '—'} · ${widget.item.unit ?? t('وحدة', 'unit')}',
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.sm,
                  vertical: ds.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(ds.radii.pill),
                ),
                child: DSText(
                  _badgeLabel(context),
                  role: DSTextRole.caption,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: t('في النظام', 'System'),
                  value: _system.toStringAsFixed(0),
                  color: ds.colors.textSecondary,
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                flex: 2,
                child: _CountInput(controller: _ctrl, focus: _focus),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(label, role: DSTextRole.caption, color: color),
        SizedBox(height: 2),
        DSText(value, role: DSTextRole.title),
      ],
    );
  }
}

class _CountInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;

  const _CountInput({required this.controller, required this.focus});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          t('العدد الفعلي', 'Physical count'),
          role: DSTextRole.caption,
          color: ds.colors.textSecondary,
        ),
        SizedBox(height: 2),
        Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: ds.spacing.md,
            vertical: ds.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: ds.colors.surfaceAlt,
            borderRadius: BorderRadius.circular(ds.radii.medium),
            border: Border.all(color: ds.colors.border),
          ),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Stack(
              children: [
                if (controller.text.isEmpty)
                  DSText(
                    '0',
                    role: DSTextRole.title,
                    color: ds.colors.textMuted,
                  ),
                EditableText(
                  controller: controller,
                  focusNode: focus,
                  style: ds.typography.title
                      .copyWith(color: ds.colors.textPrimary),
                  cursorColor: ds.colors.primary,
                  backgroundCursorColor: ds.colors.textMuted,
                  maxLines: 1,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;

  const _ConfirmDialog({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(ds.spacing.lg),
        child: Container(
          padding: EdgeInsetsDirectional.all(ds.spacing.lg),
          decoration: BoxDecoration(
            color: ds.colors.surface,
            borderRadius: BorderRadius.circular(ds.radii.xLarge),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DSText(title, role: DSTextRole.headline),
              SizedBox(height: ds.spacing.sm),
              DSText(body,
                  role: DSTextRole.body,
                  color: ds.colors.textSecondary,
                  maxLines: 4),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: t('إلغاء', 'Cancel'),
                      variant: DSButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(false),
                      expanded: true,
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: t('تأكيد', 'Confirm'),
                      onPressed: () => Navigator.of(context).pop(true),
                      expanded: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          DSLineIcon(type: icon, color: ds.colors.textMuted, size: ds.spacing.xl),
          SizedBox(height: ds.spacing.sm),
          DSText(message,
              role: DSTextRole.caption, color: ds.colors.textSecondary),
        ],
      ),
    );
  }
}
