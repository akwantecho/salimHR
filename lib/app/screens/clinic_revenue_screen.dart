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
import 'clinic_invoices_screen.dart';

/// Clinic finance drill-down (manager). Opened from the Outstanding alert on
/// the manager home screen. Shows billed / collected / outstanding for a
/// period plus revenue breakdowns by specialist and service.
class ClinicRevenueScreen extends StatefulWidget {
  const ClinicRevenueScreen({super.key});

  @override
  State<ClinicRevenueScreen> createState() => _ClinicRevenueScreenState();
}

class _ClinicRevenueScreenState extends State<ClinicRevenueScreen> {
  bool _loading = true;
  String? _error;
  RevenueReport? _report;
  String _period = 'month'; // 'today' | 'month' | 'year'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  ({String from, String to}) _range() {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    switch (_period) {
      case 'today':
        return (from: fmt(now), to: fmt(now));
      case 'year':
        return (from: fmt(DateTime(now.year, 1, 1)), to: fmt(now));
      default: // month
        return (from: fmt(DateTime(now.year, now.month, 1)), to: fmt(now));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = _range();
    try {
      final report =
          await context.clinicService.getRevenue(from: r.from, to: r.to);
      if (!mounted) return;
      setState(() {
        _report = report;
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

  void _setPeriod(String p) {
    if (p == _period) return;
    setState(() => _period = p);
    _load();
  }

  String _money(num v) {
    final s = v
        .toStringAsFixed(v.truncateToDouble() == v ? 0 : 3)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );
    return s;
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
                      t('المالية', 'Finance'),
                      role: DSTextRole.headline,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),

              // Period chips.
              Row(
                children: [
                  _PeriodChip(
                    label: t('اليوم', 'Today'),
                    selected: _period == 'today',
                    onTap: () => _setPeriod('today'),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  _PeriodChip(
                    label: t('هذا الشهر', 'Month'),
                    selected: _period == 'month',
                    onTap: () => _setPeriod('month'),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  _PeriodChip(
                    label: t('هذا العام', 'Year'),
                    selected: _period == 'year',
                    onTap: () => _setPeriod('year'),
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

    final r = _report;
    if (r == null) return const SizedBox.shrink();
    final currency = t('ر.ع', 'OMR');

    return ListView(
      children: [
        // Outstanding — the headline number. Taps through to the invoices
        // that make it up.
        GestureDetector(
          onTap: () => Navigator.of(context).push<void>(
            PageRouteBuilder(
              pageBuilder: (context, _, _) =>
                  const ClinicInvoicesScreen(unpaidOnly: true),
            ),
          ),
          child: DSCard(
            padding: EdgeInsetsDirectional.all(ds.spacing.lg),
            background: const Color(0xFFEC4899).withOpacity(0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DSLineIcon(
                      type: LineIconType.heart,
                      color: const Color(0xFFEC4899),
                      size: ds.spacing.lg,
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: DSText(
                        t('مستحقات غير محصّلة', 'Outstanding'),
                        role: DSTextRole.title,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                    DSLineIcon(
                      type: LineIconType.chevronForward,
                      color: const Color(0xFFEC4899),
                      size: ds.spacing.md,
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.sm),
                DSText(
                  '${_money(r.outstanding)} $currency',
                  role: DSTextRole.display,
                  color: const Color(0xFFEC4899),
                ),
                SizedBox(height: ds.spacing.xs),
                DSText(
                  t('عرض الفواتير', 'View invoices'),
                  role: DSTextRole.caption,
                  color: const Color(0xFFEC4899),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ds.spacing.md),

        // Reconciliation — how outstanding is derived: Billed − Collected.
        DSCard(
          padding: EdgeInsetsDirectional.all(ds.spacing.md),
          background: ds.colors.surface,
          shadows: ds.shadows.level1,
          child: Column(
            children: [
              _ReconLine(
                label: t('المفوتر', 'Billed'),
                value: '${_money(r.billed)} $currency',
                color: const Color(0xFF6366F1),
              ),
              SizedBox(height: ds.spacing.sm),
              _ReconLine(
                sign: '−',
                label: t('المحصّل', 'Collected'),
                value: '${_money(r.collected)} $currency',
                color: const Color(0xFF10B981),
              ),
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                    vertical: ds.spacing.sm),
                child: Container(height: 1, color: ds.colors.border),
              ),
              _ReconLine(
                sign: '=',
                label: t('المتبقّي', 'Outstanding'),
                value: '${_money(r.outstanding)} $currency',
                color: const Color(0xFFEC4899),
                emphasize: true,
              ),
              SizedBox(height: ds.spacing.md),
              // Collected vs outstanding share of what was billed.
              _CollectionBar(
                collected: r.collected.toDouble(),
                billed: r.billed.toDouble(),
              ),
              SizedBox(height: ds.spacing.xs),
              DSText(
                r.billed > 0
                    ? t(
                        'تم تحصيل ${(r.collected / r.billed * 100).round()}% من المفوتر',
                        '${(r.collected / r.billed * 100).round()}% of billed collected')
                    : t('لا فواتير في هذه الفترة', 'No invoices this period'),
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
            ],
          ),
        ),
        SizedBox(height: ds.spacing.md),

        // Billed / Collected tiles.
        Row(
          children: [
            Expanded(
              child: _MoneyTile(
                label: t('المفوتر', 'Billed'),
                value: '${_money(r.billed)} $currency',
                color: const Color(0xFF6366F1),
              ),
            ),
            SizedBox(width: ds.spacing.sm),
            Expanded(
              child: _MoneyTile(
                label: t('المحصّل', 'Collected'),
                value: '${_money(r.collected)} $currency',
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        SizedBox(height: ds.spacing.sm),
        Row(
          children: [
            Expanded(
              child: _MoneyTile(
                label: t('عدد الفواتير', 'Invoices'),
                value: '${r.invoiceCount}',
                color: const Color(0xFF3B82F6),
              ),
            ),
            SizedBox(width: ds.spacing.sm),
            Expanded(
              child: _MoneyTile(
                label: t('متوسط الفاتورة', 'Avg invoice'),
                value: '${_money(r.avgInvoice)} $currency',
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),

        if (r.bySpecialist.isNotEmpty) ...[
          SizedBox(height: ds.spacing.lg),
          SectionHeader(title: t('حسب الأخصائي', 'By Specialist')),
          ...r.bySpecialist.map((row) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                child: _BreakdownRow(
                  name: row.name,
                  value: '${_money(row.revenue)} $currency',
                  count: row.count,
                  t: t,
                ),
              )),
        ],

        if (r.byService.isNotEmpty) ...[
          SizedBox(height: ds.spacing.lg),
          SectionHeader(title: t('حسب الخدمة', 'By Service')),
          ...r.byService.map((row) => Padding(
                padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                child: _BreakdownRow(
                  name: row.name,
                  value: '${_money(row.revenue)} $currency',
                  count: row.count,
                  t: t,
                ),
              )),
        ],
        SizedBox(height: ds.spacing.md),
      ],
    );
  }
}

class _MoneyTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MoneyTile({
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

class _ReconLine extends StatelessWidget {
  final String? sign;
  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  const _ReconLine({
    required this.label,
    required this.value,
    required this.color,
    this.sign,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final role = emphasize ? DSTextRole.title : DSTextRole.body;
    return Row(
      children: [
        SizedBox(
          width: ds.spacing.lg,
          child: DSText(
            sign ?? '',
            role: DSTextRole.title,
            color: ds.colors.textMuted,
          ),
        ),
        Expanded(
          child: DSText(label, role: role, color: ds.colors.textPrimary),
        ),
        DSText(value, role: role, color: color),
      ],
    );
  }
}

class _CollectionBar extends StatelessWidget {
  final double collected;
  final double billed;

  const _CollectionBar({required this.collected, required this.billed});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final ratio =
        billed > 0 ? (collected / billed).clamp(0.0, 1.0) : 0.0;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        // Track = outstanding portion (pink); fill = collected (green).
        color: const Color(0xFFEC4899).withOpacity(0.25),
        borderRadius: BorderRadius.circular(ds.radii.pill),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: ratio == 0 ? 0.0001 : ratio,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(ds.radii.pill),
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final chipColor = ds.colors.primary;
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

class _BreakdownRow extends StatelessWidget {
  final String name;
  final String value;
  final int count;
  final String Function(String, String) t;

  const _BreakdownRow({
    required this.name,
    required this.value,
    required this.count,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      background: ds.colors.surface,
      shadows: ds.shadows.level1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(name, role: DSTextRole.title, maxLines: 1),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  t('$count فاتورة', '$count invoices'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          SizedBox(width: ds.spacing.sm),
          DSText(value, role: DSTextRole.label, color: ds.colors.primary),
        ],
      ),
    );
  }
}
