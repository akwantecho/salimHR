import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../ui/blocks.dart';

/// Clinic invoices list (manager). Opened from the Finance screen — the rows
/// that make up billed / collected / outstanding. Defaults to unpaid.
class ClinicInvoicesScreen extends StatefulWidget {
  /// Start filtered to unpaid (outstanding) invoices when true.
  final bool unpaidOnly;

  const ClinicInvoicesScreen({super.key, this.unpaidOnly = true});

  @override
  State<ClinicInvoicesScreen> createState() => _ClinicInvoicesScreenState();
}

class _ClinicInvoicesScreenState extends State<ClinicInvoicesScreen> {
  bool _loading = true;
  String? _error;
  List<Invoice> _invoices = const [];
  InvoiceSummary? _summary;
  late bool _unpaidOnly = widget.unpaidOnly;

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
    try {
      final result = await context.invoiceService
          .getClinicInvoices(unpaidOnly: _unpaidOnly);
      if (!mounted) return;
      setState(() {
        _invoices = result.invoices;
        _summary = result.summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  void _setUnpaid(bool v) {
    if (v == _unpaidOnly) return;
    setState(() => _unpaidOnly = v);
    _load();
  }

  String _money(num v) => v
      .toStringAsFixed(v.truncateToDouble() == v ? 0 : 3)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

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
                      t('الفواتير', 'Invoices'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),

              // Filter: unpaid vs all.
              Row(
                children: [
                  _Chip(
                    label: t('غير مدفوعة', 'Unpaid'),
                    selected: _unpaidOnly,
                    color: const Color(0xFFEC4899),
                    onTap: () => _setUnpaid(true),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  _Chip(
                    label: t('الكل', 'All'),
                    selected: !_unpaidOnly,
                    onTap: () => _setUnpaid(false),
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
            DSText(_error!, role: DSTextRole.caption, align: TextAlign.center),
            SizedBox(height: ds.spacing.md),
            DSButton(label: t('إعادة المحاولة', 'Retry'), onPressed: _load),
          ],
        ),
      );
    }

    final currency = t('ر.ع', 'OMR');
    final summary = _summary;

    return ListView(
      children: [
        if (summary != null) ...[
          Row(
            children: [
              Expanded(
                child: _CountTile(
                  label: t('غير مدفوعة', 'Unpaid'),
                  value: '${summary.unpaidCount}',
                  color: const Color(0xFFEC4899),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: _CountTile(
                  label: t('المتبقّي', 'Outstanding'),
                  value: '${_money(summary.unpaidAmount)} $currency',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),
        ],
        if (_invoices.isEmpty)
          Padding(
            padding: EdgeInsetsDirectional.only(top: ds.spacing.xl),
            child: Center(
              child: DSText(
                t('لا فواتير', 'No invoices'),
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
            ),
          )
        else
          ..._invoices.map((inv) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                child: _InvoiceCard(
                  invoice: inv,
                  currency: currency,
                  money: _money,
                  t: t,
                ),
              )),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String currency;
  final String Function(num) money;
  final String Function(String, String) t;

  const _InvoiceCard({
    required this.invoice,
    required this.currency,
    required this.money,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final inv = invoice;

    Color color;
    String label;
    if (inv.isFree) {
      color = const Color(0xFF64748B);
      label = t('مجانية', 'Free');
    } else if (inv.remainingAmount <= 0 && inv.totalAmount > 0) {
      color = const Color(0xFF10B981);
      label = t('مدفوعة', 'Paid');
    } else if (inv.paidAmount > 0) {
      color = const Color(0xFFF59E0B);
      label = t('جزئية', 'Partial');
    } else {
      color = const Color(0xFFEC4899);
      label = t('غير مدفوعة', 'Unpaid');
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      inv.patientName ?? t('مريض', 'Patient'),
                      role: DSTextRole.title,
                      maxLines: 1,
                    ),
                    SizedBox(height: ds.spacing.xs / 2),
                    DSText(
                      [
                        if (inv.invoiceNumber != null) '#${inv.invoiceNumber}',
                        if (inv.invoiceDate != null) inv.invoiceDate!,
                      ].join(' · '),
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              StatusPill(label: label, color: color),
            ],
          ),
          SizedBox(height: ds.spacing.md),
          Row(
            children: [
              Expanded(
                child: _Amount(
                  label: t('الإجمالي', 'Total'),
                  value: '${money(inv.totalAmount)} $currency',
                  color: ds.colors.textPrimary,
                ),
              ),
              Expanded(
                child: _Amount(
                  label: t('مدفوع', 'Paid'),
                  value: '${money(inv.paidAmount)} $currency',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _Amount(
                  label: t('متبقّي', 'Due'),
                  value: '${money(inv.remainingAmount)} $currency',
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Amount({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          label,
          role: DSTextRole.caption,
          color: ds.colors.textSecondary,
        ),
        SizedBox(height: ds.spacing.xs / 2),
        DSText(value, role: DSTextRole.label, color: color, maxLines: 1),
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
          DSText(value, role: DSTextRole.title, color: color, maxLines: 1),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _Chip({
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
