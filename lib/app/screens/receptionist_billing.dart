import 'package:flutter/widgets.dart';

import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import 'receptionist_common.dart';
import 'specialist_requests.dart' show RequestFormScaffold;

/// Receptionist "Billing" tab: outstanding-first invoice list + a KPI card.
/// Tap a row to open the collect flow.
class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isLoading = true;
  String? _error;
  bool _unpaidOnly = true;
  List<Invoice> _invoices = [];
  InvoiceSummary _summary = const InvoiceSummary();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result =
          await context.invoiceService.getInvoices(unpaidOnly: _unpaidOnly);
      if (!mounted) return;
      setState(() {
        _invoices = result.invoices;
        _summary = result.summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openInvoice(Invoice inv) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (ctx, _, _) => InvoiceDetailScreen(
          invoiceId: inv.id,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) return const ShimmerLoading();
    if (_error != null) {
      return ReceptionErrorView(error: _error!, onRetry: _load);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetricCard(
                title: t('مستحق', 'Outstanding'),
                value: formatMoney(context, _summary.unpaidAmount),
                caption: t('${_summary.unpaidCount} فاتورة غير مدفوعة',
                    '${_summary.unpaidCount} unpaid invoices'),
                accent: const Color(0xFFEF4444),
              ),
              SizedBox(height: ds.spacing.md),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: t('غير مدفوع', 'Unpaid'),
                      variant: _unpaidOnly
                          ? DSButtonVariant.primary
                          : DSButtonVariant.ghost,
                      expanded: true,
                      onPressed: () {
                        setState(() => _unpaidOnly = true);
                        _load();
                      },
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: t('الكل', 'All'),
                      variant: !_unpaidOnly
                          ? DSButtonVariant.primary
                          : DSButtonVariant.ghost,
                      expanded: true,
                      onPressed: () {
                        setState(() => _unpaidOnly = false);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),
              SectionHeader(title: t('الفواتير', 'Invoices')),
            ],
          ),
        ),
        if (_invoices.isEmpty)
          SliverToBoxAdapter(
            child: ReceptionEmpty(message: t('لا توجد فواتير', 'No invoices')),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final inv = _invoices[index];
              return GestureDetector(
                onTap: () => _openInvoice(inv),
                child: DSCard(
                  padding: EdgeInsetsDirectional.all(ds.spacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DSText(
                              inv.patientName ??
                                  (inv.invoiceNumber ?? '#${inv.id}'),
                              role: DSTextRole.title,
                              maxLines: 1,
                            ),
                            SizedBox(height: 2),
                            DSText(
                              '${inv.invoiceNumber ?? ''} · ${formatMoney(context, inv.remainingAmount)} ${t('متبقٍ', 'due')}',
                              role: DSTextRole.caption,
                              color: ds.colors.textSecondary,
                            ),
                            SizedBox(height: ds.spacing.sm),
                            StatusPill(
                              label: invoiceStatusLabel(context, inv.status),
                              color: invoiceStatusColor(inv.status),
                            ),
                          ],
                        ),
                      ),
                      DSText(formatMoney(context, inv.totalAmount),
                          role: DSTextRole.label),
                    ],
                  ),
                ),
              );
            },
            itemCount: _invoices.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.lg)),
      ],
    );
  }
}

/// Invoice detail + collect-payment form.
class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  final VoidCallback onBack;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.onBack,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isLoading = true;
  bool _submitting = false;
  String? _error;
  String? _success;
  InvoiceDetail? _detail;

  final TextEditingController _amount = TextEditingController();
  String _method = 'cash';
  CashAccount? _account;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await context.invoiceService.getInvoice(widget.invoiceId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _account = detail.cashAccounts.isNotEmpty ? detail.cashAccounts.first : null;
        if (_amount.text.isEmpty && detail.invoice.remainingAmount > 0) {
          _amount.text = detail.invoice.remainingAmount.toStringAsFixed(3);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amount.text.trim());
    return amount != null &&
        amount > 0 &&
        _account != null &&
        !_submitting &&
        (_detail?.invoice.remainingAmount ?? 0) > 0;
  }

  Future<void> _collect() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      await context.invoiceService.collectPayment(
        widget.invoiceId,
        amount: double.parse(_amount.text.trim()),
        method: _method,
        cashAccountId: _account!.id,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = tr(context, ar: 'تم تسجيل الدفعة', en: 'Payment recorded');
      });
      await _load();
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

    if (_isLoading) {
      return Container(
        color: ds.colors.background,
        child: const SafeArea(
          child: Padding(padding: EdgeInsets.all(16), child: ShimmerLoading()),
        ),
      );
    }

    final detail = _detail;
    if (detail == null) {
      return Container(
        color: ds.colors.background,
        child: SafeArea(
          child: ReceptionErrorView(error: _error ?? 'Error', onRetry: _load),
        ),
      );
    }

    final inv = detail.invoice;
    final paid = inv.remainingAmount <= 0.001;

    return RequestFormScaffold(
      title: inv.invoiceNumber ?? '#${inv.id}',
      subtitle: inv.patientName,
      onBack: widget.onBack,
      submitLabel: paid ? t('مدفوعة بالكامل', 'Fully paid') : t('تحصيل', 'Collect'),
      canSubmit: _canSubmit,
      submitting: _submitting,
      onSubmit: paid ? null : _collect,
      errorMessage: _error,
      successMessage: _success,
      children: [
        DSCard(
          padding: EdgeInsetsDirectional.all(ds.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _totalRow(context, t('الإجمالي', 'Total'), inv.totalAmount),
              _totalRow(context, t('المدفوع', 'Paid'), inv.paidAmount),
              _totalRow(context, t('المتبقي', 'Remaining'), inv.remainingAmount,
                  accent: const Color(0xFFEF4444)),
            ],
          ),
        ),
        SizedBox(height: ds.spacing.lg),
        SectionHeader(title: t('البنود', 'Items')),
        ...detail.items.map(
          (item) => Padding(
            padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
            child: DSCard(
              padding: EdgeInsetsDirectional.all(ds.spacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: DSText(item.service ?? t('بند', 'Item'),
                        role: DSTextRole.body),
                  ),
                  DSText(formatMoney(context, item.totalAmount),
                      role: DSTextRole.label),
                ],
              ),
            ),
          ),
        ),
        if (!paid) ...[
          SizedBox(height: ds.spacing.lg),
          SectionHeader(title: t('تسجيل دفعة', 'Record payment')),
          ReceptionField(
            controller: _amount,
            label: t('المبلغ', 'Amount'),
            number: true,
          ),
          SizedBox(height: ds.spacing.md),
          DSText(t('طريقة الدفع', 'Method'),
              role: DSTextRole.label, color: ds.colors.textSecondary),
          SizedBox(height: ds.spacing.xs),
          ReceptionChoiceChips<String>(
            options: const ['cash', 'card', 'bank_transfer', 'online'],
            selected: _method,
            labelOf: (m) => _methodLabel(context, m),
            onSelect: (m) => setState(() => _method = m),
          ),
          SizedBox(height: ds.spacing.md),
          if (detail.cashAccounts.isNotEmpty) ...[
            DSText(t('الحساب', 'Account'),
                role: DSTextRole.label, color: ds.colors.textSecondary),
            SizedBox(height: ds.spacing.xs),
            ReceptionChoiceChips<CashAccount>(
              options: detail.cashAccounts,
              selected: _account,
              labelOf: (a) => a.name,
              onSelect: (a) => setState(() => _account = a),
            ),
          ],
        ],
        SizedBox(height: ds.spacing.lg),
      ],
    );
  }

  String _methodLabel(BuildContext context, String m) {
    switch (m) {
      case 'card':
        return tr(context, ar: 'بطاقة', en: 'Card');
      case 'bank_transfer':
        return tr(context, ar: 'تحويل', en: 'Transfer');
      case 'online':
        return tr(context, ar: 'إلكتروني', en: 'Online');
      case 'cash':
      default:
        return tr(context, ar: 'نقدي', en: 'Cash');
    }
  }

  Widget _totalRow(BuildContext context, String label, double value,
      {Color? accent}) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DSText(label, role: DSTextRole.caption, color: ds.colors.textSecondary),
          DSText(formatMoney(context, value),
              role: DSTextRole.label, color: accent),
        ],
      ),
    );
  }
}
