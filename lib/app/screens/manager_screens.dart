import 'package:flutter/widgets.dart';

import '../../design_system/components/featured_card.dart';
import '../../design_system/components/line_icons.dart';
import '../../design_system/components/quick_action_grid.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_exceptions.dart';
import '../../services/api_provider.dart';
import '../../utils/time_format.dart';
import '../app_state.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import '../widgets/reason_prompt.dart';
import 'clinic_appointments_screen.dart';
import 'clinic_inventory_screen.dart';
import 'clinic_patients_screen.dart';
import 'clinic_revenue_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  bool _isLoading = true;
  String? _error;
  ClinicOverview? _overview;

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
      final overview = await context.clinicService.getOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _isLoading = false;
      });
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push<void>(
      PageRouteBuilder(pageBuilder: (context, _, _) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) return const ShimmerLoading();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSLineIcon(
              type: LineIconType.bell,
              color: const Color(0xFFEF4444),
              size: ds.spacing.xl,
            ),
            SizedBox(height: ds.spacing.md),
            DSText(t('حدث خطأ', 'An error occurred'),
                role: DSTextRole.title, color: const Color(0xFFEF4444)),
            SizedBox(height: ds.spacing.sm),
            DSText(_error!,
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
                align: TextAlign.center),
            SizedBox(height: ds.spacing.lg),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.lg,
                  vertical: ds.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.primary,
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: DSText(t('إعادة المحاولة', 'Retry'),
                    role: DSTextRole.label, color: const Color(0xFFFFFFFF)),
              ),
            ),
          ],
        ),
      );
    }

    final o = _overview!;
    final finance = o.financeVisible;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero: today's revenue (finance) or today's appointments.
              FeaturedCard(
                label: finance
                    ? t('إيراد اليوم', "Today's Revenue")
                    : t('مواعيد اليوم', "Today's Appointments"),
                value: finance
                    ? _formatAmount((o.today.revenue ?? 0).toDouble())
                    : '${o.today.total}',
                footer: DSText(
                  t('${o.today.completed} مكتملة · ${o.today.patientsSeen} مريض · ${o.today.staffPresent} موظف',
                      '${o.today.completed} done · ${o.today.patientsSeen} seen · ${o.today.staffPresent} staff'),
                  role: DSTextRole.caption,
                  color: ds.colors.surface.withOpacity(0.9),
                ),
              ),
              SizedBox(height: ds.spacing.lg),

              // Quick actions → drill-downs + tabs.
              QuickActionGrid(
                actions: [
                  QuickAction(
                    label: t('المواعيد', 'Appts'),
                    icon: LineIconType.calendar,
                    onTap: () =>
                        _openScreen(const ClinicAppointmentsScreen()),
                  ),
                  QuickAction(
                    label: t('المرضى', 'Patients'),
                    icon: LineIconType.heart,
                    onTap: () => _openScreen(const ClinicPatientsScreen()),
                  ),
                  QuickAction(
                    label: t('الموافقات', 'Approvals'),
                    icon: LineIconType.bookmark,
                    onTap: () =>
                        AppScope.of(context).setTab(UserRole.manager, 1),
                  ),
                  QuickAction(
                    label: t('التقارير', 'Reports'),
                    icon: LineIconType.chart,
                    onTap: () =>
                        AppScope.of(context).setTab(UserRole.manager, 2),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Today operations
              SectionHeader(title: t('اليوم', 'Today')),
              Row(
                children: [
                  Expanded(
                    child: _DashboardCard(
                      title: t('مواعيد', 'Appointments'),
                      value: '${o.today.total}',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF6366F1),
                      trend: t('${o.today.noShow} تغيّب', '${o.today.noShow} no-show'),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _DashboardCard(
                      title: t('مرضى', 'Patients Seen'),
                      value: '${o.today.patientsSeen}',
                      icon: LineIconType.heart,
                      color: const Color(0xFF10B981),
                      trend: t('اليوم', 'today'),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _DashboardCard(
                      title: t('حضور', 'Staff In'),
                      value: '${o.today.staffPresent}',
                      icon: LineIconType.bookmark,
                      color: const Color(0xFF06B6D4),
                      trend: t('موظف', 'present'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // This month
              SectionHeader(title: t('هذا الشهر', 'This Month')),
              Row(
                children: [
                  if (finance) ...[
                    Expanded(
                      child: _DashboardCard(
                        title: t('الإيراد', 'Revenue'),
                        value: _formatAmount((o.month.revenue ?? 0).toDouble()),
                        icon: LineIconType.chart,
                        color: const Color(0xFFF59E0B),
                        trend: _deltaText(context, o.month.deltaRevenue),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                  ],
                  Expanded(
                    child: _DashboardCard(
                      title: t('مرضى جدد', 'New Patients'),
                      value: '${o.month.newPatients}',
                      icon: LineIconType.heart,
                      color: const Color(0xFF8B5CF6),
                      trend: _deltaText(context, o.month.deltaNewPatients),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _DashboardCard(
                      title: t('جلسات', 'Sessions'),
                      value: '${o.month.sessionsTotal}',
                      icon: LineIconType.calendar,
                      color: const Color(0xFF3B82F6),
                      trend: _deltaText(context, o.month.deltaSessions),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Revenue breakdown (finance only)
              if (finance && o.bySpecialist.isNotEmpty) ...[
                SectionHeader(title: t('الإيراد حسب الأخصائي', 'Revenue by Specialist')),
                _RevenueBars(rows: o.bySpecialist),
                SizedBox(height: ds.spacing.lg),
              ],
              if (finance && o.byService.isNotEmpty) ...[
                SectionHeader(title: t('الإيراد حسب الخدمة', 'Revenue by Service')),
                _RevenueBars(rows: o.byService),
                SizedBox(height: ds.spacing.lg),
              ],

              // Alerts
              SectionHeader(title: t('تنبيهات', 'Alerts')),
              _AlertCard(
                title: t('مخزون منخفض', 'Low Stock'),
                subtitle: t('${o.alerts.lowStock} صنف', '${o.alerts.lowStock} items'),
                color: const Color(0xFFF59E0B),
                icon: LineIconType.chart,
                onTap: () => _openScreen(
                    const ClinicInventoryScreen(initialFilter: 'low')),
              ),
              if (o.alerts.noShowRate != null) ...[
                SizedBox(height: ds.spacing.sm),
                _AlertCard(
                  title: t('نسبة التغيّب', 'No-show Rate'),
                  subtitle: '${o.alerts.noShowRate}%',
                  color: const Color(0xFFEF4444),
                  icon: LineIconType.bell,
                  onTap: () =>
                      _openScreen(const ClinicAppointmentsScreen()),
                ),
              ],
              if (finance && (o.alerts.outstanding ?? 0) > 0) ...[
                SizedBox(height: ds.spacing.sm),
                _AlertCard(
                  title: t('مستحقات غير محصّلة', 'Outstanding'),
                  subtitle: _formatAmount((o.alerts.outstanding ?? 0).toDouble()),
                  color: const Color(0xFFEC4899),
                  icon: LineIconType.heart,
                  onTap: () => _openScreen(const ClinicRevenueScreen()),
                ),
              ],
              SizedBox(height: ds.spacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _deltaText(BuildContext context, num? delta) {
    if (delta == null) return tr(context, ar: 'الشهر', en: 'this month');
    final sign = delta >= 0 ? '+' : '';
    return '$sign$delta%';
  }
}

/// Horizontal revenue bars, scaled to the largest row.
class _RevenueBars extends StatelessWidget {
  final List<RevenueRow> rows;

  const _RevenueBars({required this.rows});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final max = rows.fold<num>(0, (m, r) => r.revenue > m ? r.revenue : m);
    return Column(
      children: rows.map((r) {
        final frac = max > 0 ? (r.revenue / max).toDouble() : 0.0;
        return Padding(
          padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DSText(r.name, role: DSTextRole.caption, maxLines: 1),
                  ),
                  DSText(
                    _short(r.revenue.toDouble()),
                    role: DSTextRole.caption,
                    color: ds.colors.textSecondary,
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(ds.radii.pill),
                child: Stack(
                  children: [
                    Container(height: 6, color: ds.colors.surfaceAlt),
                    FractionallySizedBox(
                      widthFactor: frac.clamp(0.02, 1.0),
                      child: Container(height: 6, color: ds.colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

/// Wrap widget to support RefreshIndicator with CustomScrollView
class RefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // For simplicity, just return the child
    // In a real app, you'd implement pull-to-refresh
    return child;
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final LineIconType icon;
  final Color color;
  final String trend;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
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
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(ds.radii.large),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsetsDirectional.all(ds.spacing.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: DSLineIcon(
                  type: icon,
                  color: const Color(0xFFFFFFFF),
                  size: ds.spacing.md,
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(
            value,
            role: DSTextRole.headline,
            color: const Color(0xFFFFFFFF),
          ),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            title,
            role: DSTextRole.caption,
            color: const Color(0xFFFFFFFF).withOpacity(0.9),
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            trend,
            role: DSTextRole.caption,
            color: const Color(0xFFFFFFFF).withOpacity(0.7),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final LineIconType icon;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = widget.color;
    final tappable = widget.onTap != null;

    final card = Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsetsDirectional.all(ds.spacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: DSLineIcon(
              type: widget.icon,
              color: color,
              size: ds.spacing.lg,
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  widget.title,
                  role: DSTextRole.title,
                  color: color,
                ),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  widget.subtitle,
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
          if (tappable) ...[
            SizedBox(width: ds.spacing.sm),
            DSLineIcon(
              type: LineIconType.chevronForward,
              color: color.withOpacity(0.6),
              size: ds.spacing.md,
            ),
          ],
        ],
      ),
    );

    if (!tappable) return card;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: ds.animation.fast,
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}

class ManagerApprovalsScreen extends StatefulWidget {
  const ManagerApprovalsScreen({super.key});

  @override
  State<ManagerApprovalsScreen> createState() => _ManagerApprovalsScreenState();
}

class _ManagerApprovalsScreenState extends State<ManagerApprovalsScreen> {
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovals();
    });
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hrService = context.hrService;
      await hrService.fetchPendingApprovals(
        type: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = hrService.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setFilter(String filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadApprovals();
    }
  }

  Future<void> _handleApprove(Approval approval) async {
    final hrService = context.hrService;
    bool success = false;

    switch (approval.type) {
      case ApprovalType.leave:
        success = await hrService.approveLeave(approval.id);
        break;
      case ApprovalType.medicalExcuse:
        success = await hrService.approveExcuse(approval.id);
        break;
      case ApprovalType.inventory:
        success = await hrService.approveInventoryRequest(approval.id);
        break;
      case ApprovalType.payroll:
        success = await hrService.approvePayroll(approval.id);
        break;
    }

    if (success) {
      _loadApprovals();
    }
  }

  Future<void> _handleReject(Approval approval) async {
    final reason = await promptForReason(
      context,
      title: tr(context, ar: 'سبب الرفض', en: 'Rejection Reason'),
      hint: tr(
        context,
        ar: 'اكتبي سبب الرفض ليُرسل للموظف.',
        en: 'Write the reason — it will be sent to the employee.',
      ),
      confirmLabel: tr(context, ar: 'رفض', en: 'Reject'),
    );
    if (reason == null || !mounted) return;

    final hrService = context.hrService;
    bool success = false;

    switch (approval.type) {
      case ApprovalType.leave:
        success = await hrService.rejectLeave(approval.id, reason: reason);
        break;
      case ApprovalType.medicalExcuse:
        success = await hrService.rejectExcuse(approval.id, reason: reason);
        break;
      case ApprovalType.inventory:
        success = await hrService.rejectInventoryRequest(approval.id, reason: reason);
        break;
      case ApprovalType.payroll:
        success = await hrService.rejectPayroll(approval.id, reason: reason);
        break;
    }

    if (success) {
      _loadApprovals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final hrService = context.hrService;
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSLineIcon(
              type: LineIconType.bell,
              color: const Color(0xFFEF4444),
              size: ds.spacing.xl,
            ),
            SizedBox(height: ds.spacing.md),
            DSText(
              t('حدث خطأ', 'An error occurred'),
              role: DSTextRole.title,
              color: const Color(0xFFEF4444),
            ),
            SizedBox(height: ds.spacing.sm),
            DSText(
              _error!,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
            SizedBox(height: ds.spacing.lg),
            GestureDetector(
              onTap: _loadApprovals,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.lg,
                  vertical: ds.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.primary,
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: DSText(
                  t('إعادة المحاولة', 'Retry'),
                  role: DSTextRole.label,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final approvals = hrService.pendingApprovals;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline — total pending
              FeaturedCard(
                label: t('موافقات معلقة', 'Pending Approvals'),
                value: '${hrService.totalPendingApprovals}',
                footer: DSText(
                  t('${hrService.pendingLeavesCount} إجازة · ${hrService.pendingExcusesCount} عذر · ${hrService.pendingInventoryCount} مخزون · ${hrService.pendingPayrollCount} راتب',
                      '${hrService.pendingLeavesCount} leave · ${hrService.pendingExcusesCount} excuse · ${hrService.pendingInventoryCount} stock · ${hrService.pendingPayrollCount} payroll'),
                  role: DSTextRole.caption,
                  color: ds.colors.surface.withOpacity(0.9),
                ),
              ),
              SizedBox(height: ds.spacing.lg),

              // Summary Stats Row
              Row(
                children: [
                  Expanded(
                    child: _ApprovalStatCard(
                      title: t('إجازات', 'Leaves'),
                      count: '${hrService.pendingLeavesCount}',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _ApprovalStatCard(
                      title: t('أعذار', 'Excuses'),
                      count: '${hrService.pendingExcusesCount}',
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _ApprovalStatCard(
                      title: t('مخزون', 'Inventory'),
                      count: '${hrService.pendingInventoryCount}',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _ApprovalStatCard(
                      title: t('رواتب', 'Payroll'),
                      count: '${hrService.pendingPayrollCount}',
                      color: const Color(0xFF14B8A6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Filter Section
              SectionHeader(
                title: t('قائمة الموافقات', 'Pending Approvals'),
                actionLabel: '${hrService.totalPendingApprovals}',
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _setFilter('all'),
                      child: _FilterChip(
                        label: t('الكل', 'All'),
                        isSelected: _selectedFilter == 'all',
                        color: ds.colors.primary,
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setFilter('leaves'),
                      child: _FilterChip(
                        label: t('إجازات', 'Leaves'),
                        isSelected: _selectedFilter == 'leaves',
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setFilter('excuses'),
                      child: _FilterChip(
                        label: t('طبي', 'Medical'),
                        isSelected: _selectedFilter == 'excuses',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setFilter('inventory'),
                      child: _FilterChip(
                        label: t('مخزون', 'Inventory'),
                        isSelected: _selectedFilter == 'inventory',
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setFilter('payroll'),
                      child: _FilterChip(
                        label: t('رواتب', 'Payroll'),
                        isSelected: _selectedFilter == 'payroll',
                        color: const Color(0xFF14B8A6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.md),
            ],
          ),
        ),
        if (approvals.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(ds.spacing.xl),
                child: Column(
                  children: [
                    DSLineIcon(
                      type: LineIconType.heart,
                      color: ds.colors.textMuted,
                      size: ds.spacing.xl * 2,
                    ),
                    SizedBox(height: ds.spacing.md),
                    DSText(
                      t('لا توجد موافقات معلقة', 'No pending approvals'),
                      role: DSTextRole.title,
                      color: ds.colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) => _ApprovalCardFromApi(
              approval: approvals[index],
              onApprove: () => _handleApprove(approvals[index]),
              onReject: () => _handleReject(approvals[index]),
            ),
            itemCount: approvals.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

class _ApprovalStatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _ApprovalStatCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          DSText(
            count,
            role: DSTextRole.headline,
            color: color,
          ),
          SizedBox(height: ds.spacing.xs / 2),
          DSText(
            title,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.15) : ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(
          color: isSelected ? color : ds.colors.border,
        ),
      ),
      child: DSText(
        label,
        role: DSTextRole.label,
        color: isSelected ? color : ds.colors.textSecondary,
      ),
    );
  }
}

class _ApprovalCardFromApi extends StatelessWidget {
  final Approval approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCardFromApi({
    required this.approval,
    required this.onApprove,
    required this.onReject,
  });

  Color get _typeColor {
    switch (approval.type) {
      case ApprovalType.leave:
        return const Color(0xFF3B82F6); // Blue
      case ApprovalType.medicalExcuse:
        return const Color(0xFF8B5CF6); // Violet
      case ApprovalType.inventory:
        return const Color(0xFFEF4444); // Red
      case ApprovalType.payroll:
        return const Color(0xFF14B8A6); // Teal
    }
  }

  LineIconType get _typeIcon {
    switch (approval.type) {
      case ApprovalType.leave:
        return LineIconType.calendar;
      case ApprovalType.medicalExcuse:
        return LineIconType.heart;
      case ApprovalType.inventory:
        return LineIconType.chart;
      case ApprovalType.payroll:
        return LineIconType.bookmark;
    }
  }

  String _getTypeLabel(BuildContext context) {
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    switch (approval.type) {
      case ApprovalType.leave:
        return t('إجازة', 'Leave');
      case ApprovalType.medicalExcuse:
        return t('عذر طبي', 'Medical');
      case ApprovalType.inventory:
        return t('مخزون', 'Inventory');
      case ApprovalType.payroll:
        return t('رواتب', 'Payroll');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final color = _typeColor;

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Icon
              Container(
                width: ds.spacing.xl,
                height: ds.spacing.xl,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: Center(
                  child: DSLineIcon(
                    type: _typeIcon,
                    color: color,
                    size: ds.spacing.md,
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              // Title & Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      approval.title,
                      role: DSTextRole.title,
                    ),
                    SizedBox(height: ds.spacing.xs / 2),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: ds.spacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(ds.radii.small),
                          ),
                          child: DSText(
                            _getTypeLabel(context),
                            role: DSTextRole.caption,
                            color: color,
                          ),
                        ),
                        if (approval.employeeName != null) ...[
                          SizedBox(width: ds.spacing.xs),
                          DSText(
                            approval.employeeName!,
                            role: DSTextRole.caption,
                            color: ds.colors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (approval.description != null) ...[
            SizedBox(height: ds.spacing.sm),
            DSText(
              approval.description!,
              role: DSTextRole.body,
              color: ds.colors.textSecondary,
            ),
          ],
          SizedBox(height: ds.spacing.md),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: EdgeInsetsDirectional.symmetric(
                      vertical: ds.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: DSText(
                        t('موافقة', 'Approve'),
                        role: DSTextRole.label,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: onReject,
                  child: Container(
                    padding: EdgeInsetsDirectional.symmetric(
                      vertical: ds.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: DSText(
                        t('رفض', 'Reject'),
                        role: DSTextRole.label,
                        color: const Color(0xFFEF4444),
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

class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen> {
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'month';
  Map<String, dynamic> _leavesReport = {};
  Map<String, dynamic> _bonusesReport = {};
  Map<String, dynamic> _excusesReport = {};
  RevenueReport? _revenue;
  bool _financeVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  (String, String) _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        final date = formatDateIso(now);
        return (date, date);
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return (formatDateIso(start), formatDateIso(end));
      case 'year':
        return ('${now.year}-01-01', '${now.year}-12-31');
      case 'month':
      default:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (formatDateIso(start), formatDateIso(end));
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hrService = context.hrService;
      final clinicService = context.clinicService;
      final (startDate, endDate) = _getDateRange();
      _financeVisible = context.can('finance.view');

      // Fetch all report types in parallel
      final results = await Future.wait([
        hrService.fetchReport(type: 'leaves', startDate: startDate, endDate: endDate),
        hrService.fetchReport(type: 'bonuses', startDate: startDate, endDate: endDate),
        hrService.fetchReport(type: 'excuses', startDate: startDate, endDate: endDate),
      ]);

      // Revenue report is best-effort and finance-gated; a failure here must
      // not blank the HR reports.
      RevenueReport? revenue;
      if (_financeVisible) {
        try {
          revenue = await clinicService.getRevenue(from: startDate, to: endDate);
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _leavesReport = results[0];
        _bonusesReport = results[1];
        _excusesReport = results[2];
        _revenue = revenue;
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

  void _setPeriod(String period) {
    if (_selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadReports();
    }
  }

  String _formatK(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSLineIcon(
              type: LineIconType.bell,
              color: const Color(0xFFEF4444),
              size: ds.spacing.xl,
            ),
            SizedBox(height: ds.spacing.md),
            DSText(
              t('حدث خطأ', 'An error occurred'),
              role: DSTextRole.title,
              color: const Color(0xFFEF4444),
            ),
            SizedBox(height: ds.spacing.lg),
            GestureDetector(
              onTap: _loadReports,
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.lg,
                  vertical: ds.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.primary,
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                ),
                child: DSText(
                  t('إعادة المحاولة', 'Retry'),
                  role: DSTextRole.label,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Extract summary data
    final leavesSummary = _leavesReport['summary'] as Map<String, dynamic>? ?? {};
    final bonusesSummary = _bonusesReport['summary'] as Map<String, dynamic>? ?? {};
    final excusesSummary = _excusesReport['summary'] as Map<String, dynamic>? ?? {};

    final totalLeaves = leavesSummary['total_requests'] ?? 0;
    final totalLeaveDays = leavesSummary['total_days'] ?? 0;
    final approvedLeaves = leavesSummary['approved'] ?? 0;
    final totalBonuses = (bonusesSummary['total_bonuses'] ?? 0).toDouble();
    final totalDeductions = (bonusesSummary['total_deductions'] ?? 0).toDouble();
    final totalExcuses = excusesSummary['total_excuses'] ?? 0;

    final reports = [
      _ReportData(
        title: t('تقارير الإجازات', 'Leave Reports'),
        subtitle: t('$totalLeaves طلب • $totalLeaveDays يوم', '$totalLeaves requests • $totalLeaveDays days'),
        value: '$approvedLeaves',
        change: t('موافق عليه', 'approved'),
        color: const Color(0xFF3B82F6),
        icon: LineIconType.calendar,
      ),
      _ReportData(
        title: t('تقارير المكافآت', 'Bonus Reports'),
        subtitle: t('${bonusesSummary['total_entries'] ?? 0} سجل', '${bonusesSummary['total_entries'] ?? 0} entries'),
        value: '${totalBonuses.toStringAsFixed(0)}',
        change: t('ر.ع', 'OMR'),
        color: const Color(0xFF10B981),
        icon: LineIconType.bookmark,
      ),
      _ReportData(
        title: t('تقارير الخصومات', 'Deduction Reports'),
        subtitle: t('من المكافآت والخصومات', 'From bonuses & deductions'),
        value: '${totalDeductions.toStringAsFixed(0)}',
        change: t('ر.ع', 'OMR'),
        color: const Color(0xFFEF4444),
        icon: LineIconType.chart,
      ),
      _ReportData(
        title: t('الأعذار الطبية', 'Medical Excuses'),
        subtitle: t('$totalExcuses عذر طبي', '$totalExcuses excuses'),
        value: '${excusesSummary['approved'] ?? 0}',
        change: t('موافق عليه', 'approved'),
        color: const Color(0xFF8B5CF6),
        icon: LineIconType.heart,
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Stats
              Row(
                children: [
                  Expanded(
                    child: _ReportStatCard(
                      title: t('إجمالي المكافآت', 'Total Bonuses'),
                      value: '${(totalBonuses / 1000).toStringAsFixed(1)}K',
                      change: '+${bonusesSummary['total_entries'] ?? 0}',
                      isPositive: true,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _ReportStatCard(
                      title: t('إجمالي الخصومات', 'Total Deductions'),
                      value: '${(totalDeductions / 1000).toStringAsFixed(1)}K',
                      change: '-',
                      isPositive: false,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Period Filter
              SectionHeader(
                title: t('التقارير', 'Reports'),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _setPeriod('today'),
                      child: _PeriodChip(
                        label: t('اليوم', 'Today'),
                        isSelected: _selectedPeriod == 'today',
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setPeriod('week'),
                      child: _PeriodChip(
                        label: t('هذا الأسبوع', 'This Week'),
                        isSelected: _selectedPeriod == 'week',
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setPeriod('month'),
                      child: _PeriodChip(
                        label: t('هذا الشهر', 'This Month'),
                        isSelected: _selectedPeriod == 'month',
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => _setPeriod('year'),
                      child: _PeriodChip(
                        label: t('هذه السنة', 'This Year'),
                        isSelected: _selectedPeriod == 'year',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.md),

              // Revenue report (finance.view only)
              if (_financeVisible && _revenue != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ReportStatCard(
                        title: t('محصّل', 'Collected'),
                        value: _formatK(_revenue!.collected.toDouble()),
                        change: t('${_revenue!.invoiceCount} فاتورة',
                            '${_revenue!.invoiceCount} inv'),
                        isPositive: true,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _ReportStatCard(
                        title: t('مستحق', 'Outstanding'),
                        value: _formatK(_revenue!.outstanding.toDouble()),
                        change: '-',
                        isPositive: false,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.lg),
                if (_revenue!.bySpecialist.isNotEmpty) ...[
                  SectionHeader(
                      title: t('الإيراد حسب الأخصائي', 'Revenue by Specialist')),
                  _RevenueBars(rows: _revenue!.bySpecialist),
                  SizedBox(height: ds.spacing.lg),
                ],
                if (_revenue!.byService.isNotEmpty) ...[
                  SectionHeader(
                      title: t('الإيراد حسب الخدمة', 'Revenue by Service')),
                  _RevenueBars(rows: _revenue!.byService),
                  SizedBox(height: ds.spacing.lg),
                ],
                SectionHeader(title: t('تقارير الموارد البشرية', 'HR Reports')),
              ],
            ],
          ),
        ),
        SliverSeparatedList(
          itemBuilder: (context, index) => _ReportCard(data: reports[index]),
          itemCount: reports.length,
          spacing: ds.spacing.sm,
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

class _ReportData {
  final String title;
  final String subtitle;
  final String value;
  final String change;
  final Color color;
  final LineIconType icon;

  _ReportData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.change,
    required this.color,
    required this.icon,
  });
}

class _ReportStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final Color color;

  const _ReportStatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.color,
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
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(ds.radii.large),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DSText(
            title,
            role: DSTextRole.caption,
            color: const Color(0xFFFFFFFF).withOpacity(0.9),
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            value,
            role: DSTextRole.headline,
            color: const Color(0xFFFFFFFF),
          ),
          SizedBox(height: ds.spacing.xs),
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: ds.spacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(ds.radii.small),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DSLineIcon(
                  type: isPositive ? LineIconType.chart : LineIconType.chart,
                  color: const Color(0xFFFFFFFF),
                  size: 10,
                ),
                SizedBox(width: ds.spacing.xs / 2),
                DSText(
                  change,
                  role: DSTextRole.caption,
                  color: const Color(0xFFFFFFFF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? ds.colors.primary.withOpacity(0.15)
            : ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(
          color: isSelected ? ds.colors.primary : ds.colors.border,
        ),
      ),
      child: DSText(
        label,
        role: DSTextRole.label,
        color: isSelected ? ds.colors.primary : ds.colors.textSecondary,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _ReportData data;

  const _ReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final isPositive = data.change.startsWith('+');

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: ds.spacing.xl,
                height: ds.spacing.xl,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      data.color,
                      data.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: DSLineIcon(
                    type: data.icon,
                    color: const Color(0xFFFFFFFF),
                    size: ds.spacing.md,
                  ),
                ),
              ),
              SizedBox(width: ds.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      data.title,
                      role: DSTextRole.title,
                    ),
                    SizedBox(height: ds.spacing.xs / 2),
                    DSText(
                      data.subtitle,
                      role: DSTextRole.caption,
                      color: ds.colors.textSecondary,
                    ),
                  ],
                ),
              ),
              // Change Badge
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ds.radii.small),
                ),
                child: DSText(
                  data.change,
                  role: DSTextRole.caption,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),

          // Value
          DSText(
            data.value,
            role: DSTextRole.headline,
            color: data.color,
          ),
        ],
      ),
    );
  }
}

