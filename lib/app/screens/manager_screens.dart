import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_button.dart';
import '../../design_system/primitives/ds_card.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../models/reception.dart';
import '../../services/api_provider.dart';
import '../../utils/time_format.dart';
import '../app_state.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/reason_prompt.dart';
import 'reception_screens.dart'
    show ReceptionNotifyScreen, ReceptionAppointmentCard;
import 'specialist_screens.dart' show PromoBannerCarousel;

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  bool _isLoading = true;
  String? _error;
  HRDashboard? _dashboard;
  List<ScheduleAcknowledgement> _acks = [];
  Map<String, dynamic> _mstats = {};
  List<PromoBanner> _banners = [];

  @override
  void initState() {
    super.initState();
    // Delay the API call to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    final lang = AppScope.of(context).locale.languageCode;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hrService = context.hrService;
      await hrService.fetchDashboard();
      final acks = await hrService.fetchScheduleAcknowledgements();
      final mstats = await hrService.fetchManagerDashboard();
      final banners = await hrService.fetchPromoBanners(lang: lang);

      if (!mounted) return;

      setState(() {
        _dashboard = hrService.dashboard;
        _acks = acks;
        _mstats = mstats;
        _banners = banners;
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

  int _mstat(String key) => (_mstats[key] as num?)?.toInt() ?? 0;

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
            SizedBox(height: ds.spacing.sm),
            DSText(
              _error!,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
            ),
            SizedBox(height: ds.spacing.lg),
            GestureDetector(
              onTap: _loadDashboard,
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

    final dashboard = _dashboard;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotional banners
                if (_banners.isNotEmpty) ...[
                  PromoBannerCarousel(banners: _banners),
                  SizedBox(height: ds.spacing.lg),
                ],

                // Rich clinic stats
                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        title: t('مواعيد اليوم', 'Today'),
                        value: '${_mstat('appointments_today')}',
                        icon: LineIconType.calendar,
                        color: const Color(0xFF6366F1),
                        trend: t('موعد', 'appts'),
                        onTap: () => Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (c, _, _) =>
                                const ManagerAppointmentsScreen())),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _DashboardCard(
                        title: t('مكتملة اليوم', 'Completed'),
                        value: '${_mstat('completed_today')}',
                        icon: LineIconType.heart,
                        color: const Color(0xFF10B981),
                        trend: t('جلسة', 'sessions'),
                        onTap: () => Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (c, _, _) =>
                                const ManagerAppointmentsScreen())),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        title: t('إجمالي المواعيد', 'Total Appointments'),
                        value: '${_mstat('appointments_total')}',
                        icon: LineIconType.calendar,
                        color: const Color(0xFFF59E0B),
                        trend: t('كل المواعيد', 'all time'),
                        onTap: () => Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (c, _, _) =>
                                const ManagerAppointmentsScreen())),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _DashboardCard(
                        title: t('المرضى', 'Patients'),
                        value: '${_mstat('patients_total')}',
                        icon: LineIconType.bookmark,
                        color: const Color(0xFF8B5CF6),
                        trend: t('مسجّل', 'total'),
                        onTap: () => Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (c, _, _) =>
                                const ManagerAppointmentsScreen())),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        title: t('الموظفين', 'Staff'),
                        value: '${_mstat('employees_total')}',
                        icon: LineIconType.home,
                        color: const Color(0xFF06B6D4),
                        trend: t('${_mstat('specialists_total')} أخصائي',
                            '${_mstat('specialists_total')} specialists'),
                        onTap: () => Navigator.of(context).push(PageRouteBuilder(
                            pageBuilder: (c, _, _) =>
                                const ManagerStaffScreen())),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _DashboardCard(
                        title: t('موافقات معلقة', 'Pending'),
                        value: '${dashboard?.totalPendingApprovals ?? 0}',
                        icon: LineIconType.bell,
                        color: const Color(0xFFEC4899),
                        trend: t('تحتاج إجراء', 'need action'),
                        onTap: () =>
                            AppScope.of(context).setTab(UserRole.manager, 1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.lg),

                // Quick links
                SectionHeader(title: t('روابط سريعة', 'Quick Links')),
                Row(
                  children: [
                    Expanded(
                      child: _MgrLink(
                        label: t('نظرة المواعيد', 'Appointments'),
                        icon: LineIconType.calendar,
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, _, _) =>
                                const ManagerAppointmentsScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _MgrLink(
                        label: t('الموظفين', 'Staff'),
                        icon: LineIconType.home,
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, _, _) =>
                                const ManagerStaffScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _MgrLink(
                        label: t('الفواتير', 'Invoices'),
                        icon: LineIconType.chart,
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, _, _) =>
                                const ManagerInvoicesScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _MgrLink(
                        label: t('إشعار', 'Notify'),
                        icon: LineIconType.bell,
                        color: const Color(0xFF06B6D4),
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, _, _) =>
                                const ReceptionNotifyScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _MgrLink(
                        label: t('ملاحظات الموظفين', 'Employee Notes'),
                        icon: LineIconType.chat,
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, _, _) =>
                                const ManagerNotesScreen(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _MgrLink(
                        label: t('تسجيل مصروف', 'Record Expense'),
                        icon: LineIconType.chart,
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (context, _, _) =>
                                const AdminExpenseScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _MgrLink(
                        label: t('التنبيهات', 'Notifications'),
                        icon: LineIconType.bell,
                        color: const Color(0xFFEC4899),
                        onTap: () => AppScope.of(context).showNotifications(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.lg),

                // Today's schedule acknowledgements
                if (_acks.isNotEmpty) ...[
                  SectionHeader(
                    title: t('اعتماد جداول اليوم', 'Today\'s Schedule Confirmations'),
                    actionLabel:
                        '${_acks.where((a) => a.acknowledged).length}/${_acks.length}',
                  ),
                  _ScheduleAckList(items: _acks),
                  SizedBox(height: ds.spacing.lg),
                ],

                // Pending Approvals Section
                SectionHeader(
                  title: t('موافقات معلقة', 'Pending Approvals'),
                  actionLabel: t('عرض الكل', 'View all'),
                  onAction: () =>
                      AppScope.of(context).setTab(UserRole.manager, 1),
                ),
                _ApprovalSummaryCard(
                  items: [
                    _ApprovalItem(
                      t('إجازات', 'Leaves'),
                      '${dashboard?.pendingLeaves ?? 0}',
                      const Color(0xFF3B82F6),
                    ),
                    _ApprovalItem(
                      t('أعذار طبية', 'Medical'),
                      '${dashboard?.pendingExcuses ?? 0}',
                      const Color(0xFF8B5CF6),
                    ),
                    _ApprovalItem(
                      t('رواتب', 'Payroll'),
                      '${dashboard?.pendingPayrolls ?? 0}',
                      const Color(0xFF14B8A6),
                    ),
                  ],
                ),
                SizedBox(height: ds.spacing.lg),

                // Alerts Section
                if ((dashboard?.pendingLeaves ?? 0) > 0 ||
                    (dashboard?.pendingPayrolls ?? 0) > 0) ...[
                  SectionHeader(title: t('تنبيهات مهمة', 'Important Alerts')),
                  if ((dashboard?.pendingLeaves ?? 0) > 0)
                    _AlertCard(
                      title: t('إجازات معلقة', 'Pending Leaves'),
                      subtitle: t(
                        '${dashboard?.pendingLeaves} طلب بانتظار الموافقة',
                        '${dashboard?.pendingLeaves} requests awaiting approval',
                      ),
                      color: const Color(0xFF3B82F6),
                      icon: LineIconType.calendar,
                    ),
                  if ((dashboard?.pendingLeaves ?? 0) > 0)
                    SizedBox(height: ds.spacing.sm),
                  if ((dashboard?.pendingPayrolls ?? 0) > 0)
                    _AlertCard(
                      title: t('رواتب معلقة', 'Pending Payroll'),
                      subtitle: t(
                        '${dashboard?.pendingPayrolls} ملف بانتظار الاعتماد',
                        '${dashboard?.pendingPayrolls} files awaiting approval',
                      ),
                      color: const Color(0xFFEF4444),
                      icon: LineIconType.heart,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final card = Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(ds.radii.large),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Compact single-row layout: icon beside the value + title, so cards
      // stay short.
      child: Row(
        children: [
          Container(
            padding: EdgeInsetsDirectional.all(ds.spacing.xs),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: DSLineIcon(
              type: icon,
              color: const Color(0xFFFFFFFF),
              size: ds.spacing.md,
            ),
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DSText(
                  value,
                  role: DSTextRole.title,
                  color: const Color(0xFFFFFFFF),
                  maxLines: 1,
                ),
                DSText(
                  title,
                  role: DSTextRole.caption,
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _ApprovalItem {
  final String label;
  final String count;
  final Color color;
  _ApprovalItem(this.label, this.count, this.color);
}

class _ApprovalSummaryCard extends StatelessWidget {
  final List<_ApprovalItem> items;

  const _ApprovalSummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Column(
            children: [
              Container(
                width: ds.spacing.xl + ds.spacing.sm,
                height: ds.spacing.xl + ds.spacing.sm,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: DSText(
                    item.count,
                    role: DSTextRole.title,
                    color: item.color,
                  ),
                ),
              ),
              SizedBox(height: ds.spacing.xs),
              DSText(
                item.label,
                role: DSTextRole.caption,
                color: ds.colors.textSecondary,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final LineIconType icon;

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsetsDirectional.all(ds.spacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: DSLineIcon(type: icon, color: color, size: ds.spacing.lg),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(title, role: DSTextRole.title, color: color),
                SizedBox(height: ds.spacing.xs / 2),
                DSText(
                  subtitle,
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
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
        success = await hrService.rejectInventoryRequest(
          approval.id,
          reason: reason,
        );
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
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.lg)),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          DSText(count, role: DSTextRole.headline, color: color),
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
        color: isSelected ? color.withValues(alpha: 0.15) : ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(color: isSelected ? color : ds.colors.border),
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
            color: color.withValues(alpha: 0.08),
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
                  color: color.withValues(alpha: 0.12),
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
                    DSText(approval.title, role: DSTextRole.title),
                    SizedBox(height: ds.spacing.xs / 2),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: ds.spacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ds.radii.medium),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
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
      final (startDate, endDate) = _getDateRange();

      // Fetch all report types in parallel
      final results = await Future.wait([
        hrService.fetchReport(
          type: 'leaves',
          startDate: startDate,
          endDate: endDate,
        ),
        hrService.fetchReport(
          type: 'bonuses',
          startDate: startDate,
          endDate: endDate,
        ),
        hrService.fetchReport(
          type: 'excuses',
          startDate: startDate,
          endDate: endDate,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _leavesReport = results[0];
        _bonusesReport = results[1];
        _excusesReport = results[2];
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
    final leavesSummary =
        _leavesReport['summary'] as Map<String, dynamic>? ?? {};
    final bonusesSummary =
        _bonusesReport['summary'] as Map<String, dynamic>? ?? {};
    final excusesSummary =
        _excusesReport['summary'] as Map<String, dynamic>? ?? {};

    final totalLeaves = leavesSummary['total_requests'] ?? 0;
    final totalLeaveDays = leavesSummary['total_days'] ?? 0;
    final approvedLeaves = leavesSummary['approved'] ?? 0;
    final totalBonuses = (bonusesSummary['total_bonuses'] ?? 0).toDouble();
    final totalDeductions = (bonusesSummary['total_deductions'] ?? 0)
        .toDouble();
    final totalExcuses = excusesSummary['total_excuses'] ?? 0;

    final reports = [
      _ReportData(
        title: t('تقارير الإجازات', 'Leave Reports'),
        subtitle: t(
          '$totalLeaves طلب • $totalLeaveDays يوم',
          '$totalLeaves requests • $totalLeaveDays days',
        ),
        value: '$approvedLeaves',
        change: t('موافق عليه', 'approved'),
        color: const Color(0xFF3B82F6),
        icon: LineIconType.calendar,
        chartData: [0.4, 0.6, 0.8, 0.7, 0.9, 1.0],
      ),
      _ReportData(
        title: t('تقارير المكافآت', 'Bonus Reports'),
        subtitle: t(
          '${bonusesSummary['total_entries'] ?? 0} سجل',
          '${bonusesSummary['total_entries'] ?? 0} entries',
        ),
        value: '${totalBonuses.toStringAsFixed(0)}',
        change: t('ر.ع', 'OMR'),
        color: const Color(0xFF10B981),
        icon: LineIconType.bookmark,
        chartData: [0.3, 0.5, 0.4, 0.7, 0.8, 0.9],
      ),
      _ReportData(
        title: t('تقارير الخصومات', 'Deduction Reports'),
        subtitle: t('من المكافآت والخصومات', 'From bonuses & deductions'),
        value: '${totalDeductions.toStringAsFixed(0)}',
        change: t('ر.ع', 'OMR'),
        color: const Color(0xFFEF4444),
        icon: LineIconType.chart,
        chartData: [0.8, 0.7, 0.6, 0.5, 0.4, 0.3],
      ),
      _ReportData(
        title: t('الأعذار الطبية', 'Medical Excuses'),
        subtitle: t('$totalExcuses عذر طبي', '$totalExcuses excuses'),
        value: '${excusesSummary['approved'] ?? 0}',
        change: t('موافق عليه', 'approved'),
        color: const Color(0xFF8B5CF6),
        icon: LineIconType.heart,
        chartData: [0.7, 0.75, 0.8, 0.85, 0.9, 0.95],
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
              SectionHeader(title: t('التقارير', 'Reports')),
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
            ],
          ),
        ),
        SliverSeparatedList(
          itemBuilder: (context, index) => _ReportCard(data: reports[index]),
          itemCount: reports.length,
          spacing: ds.spacing.sm,
        ),
        SliverToBoxAdapter(child: SizedBox(height: ds.spacing.lg)),
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
  final List<double> chartData;

  _ReportData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.change,
    required this.color,
    required this.icon,
    required this.chartData,
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
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(ds.radii.large),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
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
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
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

  const _PeriodChip({required this.label, required this.isSelected});

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
            ? ds.colors.primary.withValues(alpha: 0.15)
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
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final isPositive = data.change.startsWith('+');

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.08),
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
                    colors: [data.color, data.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(ds.radii.medium),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.3),
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
                    DSText(data.title, role: DSTextRole.title),
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
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
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

          // Value and Mini Chart Row
          Row(
            children: [
              Expanded(
                child: DSText(
                  data.value,
                  role: DSTextRole.headline,
                  color: data.color,
                ),
              ),
              // Mini Bar Chart
              SizedBox(
                width: 80,
                height: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.chartData.map((value) {
                    return Container(
                      width: 8,
                      height: 32 * value,
                      decoration: BoxDecoration(
                        color: data.color.withValues(
                          alpha: 0.3 + (value * 0.5),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),

          // Action Button
          Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.symmetric(vertical: ds.spacing.sm),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(ds.radii.medium),
              border: Border.all(color: data.color.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: DSText(
                t('عرض التقرير', 'View Report'),
                role: DSTextRole.label,
                color: data.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin list showing which specialists have confirmed today's schedule and
/// when. Green with a time = confirmed; red = still pending.
class _ScheduleAckList extends StatelessWidget {
  final List<ScheduleAcknowledgement> items;

  const _ScheduleAckList({required this.items});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: EdgeInsetsDirectional.symmetric(
                  vertical: ds.spacing.xs,
                ),
                color: ds.colors.border.withValues(alpha: 0.5),
              ),
            _ScheduleAckRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ScheduleAckRow extends StatelessWidget {
  final ScheduleAcknowledgement item;

  const _ScheduleAckRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final done = item.acknowledged;
    final color = done ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Padding(
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      child: Row(
        children: [
          // Status dot
          Container(
            width: ds.spacing.sm + 2,
            height: ds.spacing.sm + 2,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: ds.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(item.specialistName, role: DSTextRole.title),
                SizedBox(height: 2),
                DSText(
                  t('${item.sessionsCount} جلسات', '${item.sessionsCount} sessions'),
                  role: DSTextRole.caption,
                  color: ds.colors.textMuted,
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ds.radii.pill),
            ),
            child: DSText(
              done && item.acknowledgedAt != null
                  ? '${t('اعتمد ', 'Confirmed ')}${formatTime12h(context, '${item.acknowledgedAt!.hour.toString().padLeft(2, '0')}:${item.acknowledgedAt!.minute.toString().padLeft(2, '0')}')}'
                  : t('لم يعتمد', 'Pending'),
              role: DSTextRole.caption,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MANAGER QUICK LINK ====================

class _MgrLink extends StatelessWidget {
  final String label;
  final LineIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _MgrLink({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          vertical: ds.spacing.md,
          horizontal: ds.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: ds.colors.surface,
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(color: ds.colors.border),
        ),
        child: Column(
          children: [
            Container(
              width: ds.spacing.xl,
              height: ds.spacing.xl,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: Center(
                child: DSLineIcon(type: icon, color: color, size: ds.spacing.md),
              ),
            ),
            SizedBox(height: ds.spacing.xs),
            DSText(
              label,
              role: DSTextRole.caption,
              color: ds.colors.textSecondary,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MANAGER APPOINTMENTS OVERVIEW ====================

class ManagerAppointmentsScreen extends StatefulWidget {
  const ManagerAppointmentsScreen({super.key});

  @override
  State<ManagerAppointmentsScreen> createState() =>
      _ManagerAppointmentsScreenState();
}

class _ManagerAppointmentsScreenState extends State<ManagerAppointmentsScreen> {
  bool _loading = true;
  DateTime _date = DateTime.now();
  List<ReceptionAppointment> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await context.hrService.fetchClinicAppointments(date: _dateStr);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Map<String, List<ReceptionAppointment>> _bySpecialist() {
    final map = <String, List<ReceptionAppointment>>{};
    for (final a in _items) {
      final key = a.specialistName ?? tr(context, ar: 'غير محدد', en: 'Unassigned');
      map.putIfAbsent(key, () => []).add(a);
    }
    for (final list in map.values) {
      list.sort((x, y) => (x.startTime ?? '').compareTo(y.startTime ?? ''));
    }
    return map;
  }

  void _shift(int days) {
    setState(() => _date = _date.add(Duration(days: days)));
    _load();
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('مواعيد العيادة', 'Clinic Appointments'), role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              DSCard(
                padding: EdgeInsetsDirectional.all(ds.spacing.xs),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _shift(-1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                        child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.md),
                      ),
                    ),
                    Expanded(child: Center(child: DSText(_dateStr, role: DSTextRole.title))),
                    GestureDetector(
                      onTap: () => _shift(1),
                      child: Transform.flip(
                        flipX: true,
                        child: Padding(
                          padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                          child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : _items.isEmpty
                    ? Center(child: DSText(t('لا توجد مواعيد', 'No appointments'), role: DSTextRole.body, color: ds.colors.textSecondary))
                    : ListView(
                        children: [
                          for (final entry in _bySpecialist().entries) ...[
                            Padding(
                              padding: EdgeInsetsDirectional.only(top: ds.spacing.sm, bottom: ds.spacing.xs),
                              child: Row(
                                children: [
                                  DSLineIcon(type: LineIconType.heart, color: ds.colors.primary, size: ds.spacing.md),
                                  SizedBox(width: ds.spacing.sm),
                                  Expanded(child: DSText(entry.key, role: DSTextRole.title)),
                                  Container(
                                    padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.sm, vertical: ds.spacing.xs / 2),
                                    decoration: BoxDecoration(color: ds.colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(ds.radii.pill)),
                                    child: DSText('${entry.value.length}', role: DSTextRole.caption, color: ds.colors.primary),
                                  ),
                                ],
                              ),
                            ),
                            for (final a in entry.value)
                              Padding(
                                padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
                                child: ReceptionAppointmentCard(appointment: a),
                              ),
                            SizedBox(height: ds.spacing.sm),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MANAGER STAFF DIRECTORY ====================

class ManagerStaffScreen extends StatefulWidget {
  const ManagerStaffScreen({super.key});

  @override
  State<ManagerStaffScreen> createState() => _ManagerStaffScreenState();
}

class _ManagerStaffScreenState extends State<ManagerStaffScreen> {
  bool _loading = true;
  List<StaffMember> _staff = [];
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final staff = await context.hrService.fetchClinicStaff();
    if (!mounted) return;
    setState(() {
      _staff = staff;
      _loading = false;
    });
  }

  Future<void> _toggle(StaffMember e) async {
    setState(() => _busy.add(e.id));
    final newState = await context.hrService.toggleEmployeeAccess(e.id);
    if (!mounted) return;
    setState(() {
      _busy.remove(e.id);
      if (newState != null) {
        final i = _staff.indexWhere((s) => s.id == e.id);
        if (i != -1) _staff[i] = _staff[i].copyWith(accessEnabled: newState);
      }
    });
  }

  String _typeLabel(BuildContext context, String? type) {
    switch (type) {
      case 'specialist':
        return tr(context, ar: 'أخصائي', en: 'Specialist');
      case 'admin':
        return tr(context, ar: 'إداري', en: 'Admin');
      case 'receptionist':
        return tr(context, ar: 'استقبال', en: 'Reception');
      default:
        return tr(context, ar: 'موظف', en: 'Staff');
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('الموظفين', 'Staff'), role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : ListView.separated(
                        itemCount: _staff.length,
                        separatorBuilder: (_, _) => SizedBox(height: ds.spacing.sm),
                        itemBuilder: (context, i) {
                          final e = _staff[i];
                          final active = e.status == 'active';
                          final color = active ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
                          return DSCard(
                            padding: EdgeInsetsDirectional.all(ds.spacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: ds.spacing.xl,
                                      height: ds.spacing.xl,
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(ds.radii.medium)),
                                      child: Center(child: DSLineIcon(type: LineIconType.bookmark, color: color, size: ds.spacing.md)),
                                    ),
                                    SizedBox(width: ds.spacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          DSText(e.name, role: DSTextRole.title, maxLines: 1),
                                          SizedBox(height: 2),
                                          DSText(
                                            '${_typeLabel(context, e.type)}${e.department != null ? ' · ${e.department}' : ''}',
                                            role: DSTextRole.caption,
                                            color: ds.colors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (e.todayAppointments > 0)
                                      Container(
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.sm, vertical: ds.spacing.xs / 2),
                                        decoration: BoxDecoration(color: ds.colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(ds.radii.pill)),
                                        child: DSText(t('${e.todayAppointments} اليوم', '${e.todayAppointments} today'), role: DSTextRole.caption, color: ds.colors.primary),
                                      ),
                                  ],
                                ),
                                if (e.hasAccount) ...[
                                  SizedBox(height: ds.spacing.sm),
                                  Container(height: 1, color: ds.colors.border.withValues(alpha: 0.5)),
                                  SizedBox(height: ds.spacing.sm),
                                  Row(
                                    children: [
                                      DSLineIcon(
                                        type: LineIconType.home,
                                        color: ds.colors.textMuted,
                                        size: ds.spacing.sm + 2,
                                      ),
                                      SizedBox(width: ds.spacing.xs),
                                      Expanded(
                                        child: DSText(
                                          t('الدخول للتطبيق', 'App access'),
                                          role: DSTextRole.caption,
                                          color: ds.colors.textSecondary,
                                        ),
                                      ),
                                      _AccessToggle(
                                        enabled: e.accessEnabled,
                                        busy: _busy.contains(e.id),
                                        onTap: () => _toggle(e),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill toggle for enabling/disabling an employee's app access.
class _AccessToggle extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _AccessToggle({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = enabled ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md,
          vertical: ds.spacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(ds.radii.pill),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ds.spacing.sm,
              height: ds.spacing.sm,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: ds.spacing.xs),
            DSText(
              busy
                  ? tr(context, ar: '...', en: '...')
                  : enabled
                  ? tr(context, ar: 'مفعّل', en: 'Enabled')
                  : tr(context, ar: 'موقوف', en: 'Disabled'),
              role: DSTextRole.caption,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MANAGER INVOICES ====================

class ManagerInvoicesScreen extends StatefulWidget {
  const ManagerInvoicesScreen({super.key});

  @override
  State<ManagerInvoicesScreen> createState() => _ManagerInvoicesScreenState();
}

class _ManagerInvoicesScreenState extends State<ManagerInvoicesScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<InvoiceItem> _invoices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final data = await context.hrService.fetchManagerInvoices();
    if (!mounted) return;
    setState(() {
      _stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
      _invoices = (data['invoices'] as List).cast<InvoiceItem>();
      _loading = false;
    });
  }

  int _stat(String k) => (_stats[k] as num?)?.toInt() ?? 0;
  double _statD(String k) => (_stats[k] as num?)?.toDouble() ?? 0;

  String _money(double v) {
    final s = v.toStringAsFixed(3).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
    return tr(context, ar: '$s ر.ع', en: 'OMR $s');
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(type: LineIconType.arrowBack, color: ds.colors.primary, size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('الفواتير', 'Invoices'), role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : ListView(
                        children: [
                          // Stats
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardCard(
                                  title: t('إجمالي الإيراد', 'Total Revenue'),
                                  value: _money(_statD('revenue_total')),
                                  icon: LineIconType.chart,
                                  color: const Color(0xFF10B981),
                                  trend: t('محصّل', 'collected'),
                                ),
                              ),
                              SizedBox(width: ds.spacing.sm),
                              Expanded(
                                child: _DashboardCard(
                                  title: t('إيراد الشهر', 'This Month'),
                                  value: _money(_statD('revenue_month')),
                                  icon: LineIconType.calendar,
                                  color: const Color(0xFF6366F1),
                                  trend: t('هذا الشهر', 'month'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ds.spacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardCard(
                                  title: t('مستحقّات', 'Outstanding'),
                                  value: _money(_statD('outstanding')),
                                  icon: LineIconType.bell,
                                  color: const Color(0xFFEF4444),
                                  trend: t('${_stat('unpaid_count')} فاتورة', '${_stat('unpaid_count')} invoices'),
                                ),
                              ),
                              SizedBox(width: ds.spacing.sm),
                              Expanded(
                                child: _DashboardCard(
                                  title: t('مدفوعة', 'Paid'),
                                  value: '${_stat('paid_count')}/${_stat('total_count')}',
                                  icon: LineIconType.heart,
                                  color: const Color(0xFF8B5CF6),
                                  trend: t('فاتورة', 'invoices'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ds.spacing.lg),
                          SectionHeader(title: t('أحدث الفواتير', 'Recent Invoices')),
                          for (final inv in _invoices)
                            Padding(
                              padding: EdgeInsetsDirectional.only(bottom: ds.spacing.sm),
                              child: _InvoiceCard(invoice: inv, money: _money),
                            ),
                          SizedBox(height: ds.spacing.xl),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceItem invoice;
  final String Function(double) money;

  const _InvoiceCard({required this.invoice, required this.money});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final color = _invoiceStatusColor(invoice.status);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(invoice.patient ?? '-', role: DSTextRole.title, maxLines: 1),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(horizontal: ds.spacing.sm, vertical: ds.spacing.xs / 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(ds.radii.pill)),
                child: DSText(_invoiceStatusLabel(context, invoice.status), role: DSTextRole.caption, color: color),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          Row(
            children: [
              Expanded(
                child: DSText(
                  '${invoice.number ?? ''}${invoice.date != null ? ' · ${invoice.date!.year}-${invoice.date!.month.toString().padLeft(2, '0')}-${invoice.date!.day.toString().padLeft(2, '0')}' : ''}',
                  role: DSTextRole.caption,
                  color: ds.colors.textMuted,
                ),
              ),
              DSText(money(invoice.totalAmount), role: DSTextRole.label, color: ds.colors.textPrimary),
            ],
          ),
          if (invoice.remainingAmount > 0) ...[
            SizedBox(height: 2),
            DSText(
              tr(context, ar: 'المتبقّي: ', en: 'Remaining: ') + money(invoice.remainingAmount),
              role: DSTextRole.caption,
              color: const Color(0xFFEF4444),
            ),
          ],
        ],
      ),
    );
  }
}

Color _invoiceStatusColor(String status) {
  switch (status) {
    case 'paid':
      return const Color(0xFF10B981);
    case 'partially_paid':
      return const Color(0xFFF59E0B);
    case 'void':
      return const Color(0xFF94A3B8);
    case 'free':
      return const Color(0xFF06B6D4);
    default:
      return const Color(0xFF6366F1);
  }
}

String _invoiceStatusLabel(BuildContext context, String status) {
  switch (status) {
    case 'paid':
      return tr(context, ar: 'مدفوعة', en: 'Paid');
    case 'partially_paid':
      return tr(context, ar: 'جزئية', en: 'Partial');
    case 'posted':
      return tr(context, ar: 'مرحّلة', en: 'Posted');
    case 'void':
      return tr(context, ar: 'ملغاة', en: 'Void');
    case 'free':
      return tr(context, ar: 'مجانية', en: 'Free');
    default:
      return tr(context, ar: 'مسودّة', en: 'Draft');
  }
}

// ==================== EMPLOYEE NOTES (admin inbox) ====================

/// Admin inbox for employee notes — lists every employee→admin note (with its
/// category prefix and threaded replies) and lets the admin reply from the app.
/// Separate from the notifications screen.
class ManagerNotesScreen extends StatefulWidget {
  const ManagerNotesScreen({super.key});

  @override
  State<ManagerNotesScreen> createState() => _ManagerNotesScreenState();
}

class _ManagerNotesScreenState extends State<ManagerNotesScreen> {
  bool _loading = true;
  List<EmployeeNote> _notes = [];
  final Set<int> _replying = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final notes = await context.hrService.fetchAdminNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _reply(EmployeeNote note) async {
    final result = await Navigator.of(context).push<_ReplyResult>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0x66000000),
        pageBuilder: (context, _, _) => const _ReplySheet(),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _replying.add(note.id));
    final ok = await context.hrService.replyToNote(
      note.id,
      result.text,
      fileBytes: result.attachment?.bytes,
      filename: result.attachment?.filename,
    );
    if (!mounted) return;
    setState(() => _replying.remove(note.id));
    if (ok) await _load();
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(
                      type: LineIconType.arrowBack,
                      color: ds.colors.primary,
                      size: ds.spacing.lg,
                    ),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(
                    t('ملاحظات الموظفين', 'Employee Notes'),
                    role: DSTextRole.headline,
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : _notes.isEmpty
                        ? Center(
                            child: DSText(
                              t('لا توجد ملاحظات', 'No notes'),
                              role: DSTextRole.body,
                              color: ds.colors.textSecondary,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _notes.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: ds.spacing.sm),
                            itemBuilder: (context, i) => _ManagerNoteCard(
                              note: _notes[i],
                              replying: _replying.contains(_notes[i].id),
                              onReply: () => _reply(_notes[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerNoteCard extends StatelessWidget {
  final EmployeeNote note;
  final bool replying;
  final VoidCallback onReply;

  const _ManagerNoteCard({
    required this.note,
    required this.replying,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    return DSCard(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(
                  note.employeeName ?? t('موظف', 'Employee'),
                  role: DSTextRole.title,
                ),
              ),
              DSText(
                '${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}-${note.createdAt.day.toString().padLeft(2, '0')}',
                role: DSTextRole.caption,
                color: ds.colors.textMuted,
              ),
            ],
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(note.note, role: DSTextRole.body, color: ds.colors.textSecondary),
          if (note.attachmentUrl != null)
            NoteAttachmentChip(
              url: note.attachmentUrl!,
              name: note.attachmentName,
              isImage: note.attachmentIsImage,
            ),

          // Existing replies threaded under the note.
          for (final reply in note.replies)
            Container(
              margin: EdgeInsetsDirectional.only(
                top: ds.spacing.sm,
                start: ds.spacing.lg,
              ),
              padding: EdgeInsetsDirectional.all(ds.spacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(ds.radii.medium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(
                    reply.creatorName ?? t('رد الإدارة', 'Admin reply'),
                    role: DSTextRole.label,
                    color: const Color(0xFFFFFFFF),
                  ),
                  SizedBox(height: 2),
                  DSText(reply.note,
                      role: DSTextRole.title, color: const Color(0xFFFFFFFF)),
                  if (reply.attachmentUrl != null)
                    NoteAttachmentChip(
                      url: reply.attachmentUrl!,
                      name: reply.attachmentName,
                      isImage: reply.attachmentIsImage,
                    ),
                ],
              ),
            ),

          SizedBox(height: ds.spacing.md),
          DSButton(
            label: replying
                ? t('جاري الإرسال...', 'Sending...')
                : t('رد', 'Reply'),
            variant: DSButtonVariant.primary,
            leading: DSLineIcon(
              type: LineIconType.chat,
              color: const Color(0xFFFFFFFF),
              size: ds.spacing.md,
            ),
            onPressed: replying ? null : onReply,
          ),
        ],
      ),
    );
  }
}

/// Result of the admin reply sheet: the text plus an optional attachment.
class _ReplyResult {
  final String text;
  final PickedAttachment? attachment;
  const _ReplyResult(this.text, this.attachment);
}

/// Bottom sheet for the admin to reply to an employee note with text and an
/// optional image/file attachment.
class _ReplySheet extends StatefulWidget {
  const _ReplySheet();

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _value = '';
  PickedAttachment? _attachment;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text != _value) setState(() => _value = _controller.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final picked = await pickAttachment(context);
    if (picked != null && mounted) setState(() => _attachment = picked);
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final canSend = _value.trim().isNotEmpty || _attachment != null;
    // Lift the sheet above the keyboard so it never covers the input/buttons.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.fromSTEB(
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.lg,
            ds.spacing.xl,
          ),
        decoration: BoxDecoration(
          color: ds.colors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ds.radii.xLarge),
            topRight: Radius.circular(ds.radii.xLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DSText(t('رد على الملاحظة', 'Reply to note'),
                  role: DSTextRole.headline),
              SizedBox(height: ds.spacing.md),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.md,
                  vertical: ds.spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: ds.colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(ds.radii.large),
                  border: Border.all(color: ds.colors.border, width: 1.5),
                ),
                child: EditableText(
                  controller: _controller,
                  focusNode: _focus,
                  style: ds.typography.body
                      .copyWith(color: ds.colors.textPrimary),
                  cursorColor: ds.colors.primary,
                  backgroundCursorColor: ds.colors.textMuted,
                  maxLines: 4,
                  minLines: 2,
                  textAlign: ds.textDirection == TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                ),
              ),
              SizedBox(height: ds.spacing.md),
              AttachmentField(
                attachment: _attachment,
                onAttach: _attach,
                onRemove: () => setState(() => _attachment = null),
              ),
              SizedBox(height: ds.spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: DSButton(
                      label: t('إلغاء', 'Cancel'),
                      variant: DSButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: DSButton(
                      label: t('إرسال', 'Send'),
                      variant: DSButtonVariant.primary,
                      onPressed: canSend
                          ? () => Navigator.of(context).pop(
                              _ReplyResult(_value.trim(), _attachment))
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ==================== ADMIN EXPENSE (record) ====================

/// Record an expense from the phone (goes to the web accounting flow). The
/// invoice image can be captured or uploaded — the fast part.
class AdminExpenseScreen extends StatefulWidget {
  const AdminExpenseScreen({super.key});

  @override
  State<AdminExpenseScreen> createState() => _AdminExpenseScreenState();
}

class _AdminExpenseScreenState extends State<AdminExpenseScreen> {
  final _vendor = TextEditingController();
  final _desc = TextEditingController();
  final _before = TextEditingController();
  final _vat = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  List<NamedRef> _categories = [];
  NamedRef? _category;
  String _payment = 'cash';
  PickedAttachment? _receipt;
  bool _loading = true;
  bool _submitting = false;
  String? _message;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _vendor.dispose();
    _desc.dispose();
    _before.dispose();
    _vat.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cats = await context.hrService.fetchExpenseCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _category = cats.isNotEmpty ? cats.first : null;
      _loading = false;
    });
  }

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  double get _total =>
      (double.tryParse(_before.text) ?? 0) + (double.tryParse(_vat.text) ?? 0);

  Future<void> _pick() async {
    final p = await pickAttachment(context);
    if (p != null && mounted) setState(() => _receipt = p);
  }

  Future<void> _submit() async {
    final before = double.tryParse(_before.text) ?? 0;
    if (_category == null || before <= 0) {
      setState(() => _message = tr(context,
          ar: 'اختر الفئة وأدخل مبلغاً صحيحاً', en: 'Choose category and a valid amount'));
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    final ok = await context.hrService.submitExpense(
      expenseDate: _dateStr,
      categoryId: _category!.id,
      amountBeforeVat: before,
      vatAmount: double.tryParse(_vat.text) ?? 0,
      vendorName: _vendor.text.trim(),
      description: _desc.text.trim(),
      paymentMethod: _payment,
      receiptBytes: _receipt?.bytes,
      receiptFilename: _receipt?.filename,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _ok = ok;
      _message = ok
          ? tr(context, ar: 'تم تسجيل المصروف', en: 'Expense recorded')
          : (context.hrService.error ??
              tr(context, ar: 'تعذّر الحفظ', en: 'Could not save'));
      if (ok) {
        _vendor.clear();
        _desc.clear();
        _before.clear();
        _vat.text = '0';
        _receipt = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final isAr = t('ar', 'en') == 'ar';

    return Container(
      color: ds.colors.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(ds.spacing.lg, ds.spacing.lg,
              ds.spacing.lg, ds.spacing.lg + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: DSLineIcon(
                        type: LineIconType.arrowBack,
                        color: ds.colors.primary,
                        size: ds.spacing.lg),
                  ),
                  SizedBox(width: ds.spacing.md),
                  DSText(t('تسجيل مصروف', 'Record Expense'),
                      role: DSTextRole.headline),
                ],
              ),
              SizedBox(height: ds.spacing.md),
              Expanded(
                child: _loading
                    ? const ShimmerLoading()
                    : ListView(
                        children: [
                          // Receipt image (fast)
                          AttachmentField(
                            attachment: _receipt,
                            onAttach: _pick,
                            onRemove: () => setState(() => _receipt = null),
                          ),
                          SizedBox(height: ds.spacing.md),
                          // Date
                          _label(t('التاريخ', 'Date')),
                          DSCard(
                            padding: EdgeInsetsDirectional.all(ds.spacing.sm),
                            child: Row(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => _date =
                                      _date.subtract(const Duration(days: 1))),
                                  child: Padding(
                                    padding:
                                        EdgeInsetsDirectional.all(ds.spacing.xs),
                                    child: DSLineIcon(
                                        type: LineIconType.arrowBack,
                                        color: ds.colors.primary,
                                        size: ds.spacing.md),
                                  ),
                                ),
                                Expanded(
                                    child: Center(
                                        child: DSText(_dateStr,
                                            role: DSTextRole.title))),
                                Transform.flip(
                                  flipX: true,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => _date =
                                        _date.add(const Duration(days: 1))),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.all(
                                          ds.spacing.xs),
                                      child: DSLineIcon(
                                          type: LineIconType.arrowBack,
                                          color: ds.colors.primary,
                                          size: ds.spacing.md),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ds.spacing.md),
                          // Category (dropdown from backend)
                          _label(t('التصنيف', 'Category')),
                          if (_categories.isEmpty)
                            DSText(
                              t('لا توجد تصنيفات (تأكد من نشر مسار التصنيفات)',
                                  'No categories (backend route not deployed)'),
                              role: DSTextRole.caption,
                              color: const Color(0xFFEF4444),
                            ),
                          Wrap(
                            spacing: ds.spacing.xs,
                            runSpacing: ds.spacing.xs,
                            children: [
                              for (final c in _categories)
                                GestureDetector(
                                  onTap: () => setState(() => _category = c),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: ds.spacing.md,
                                        vertical: ds.spacing.xs),
                                    decoration: BoxDecoration(
                                      color: _category?.id == c.id
                                          ? ds.colors.primary
                                          : ds.colors.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(ds.radii.pill),
                                      border:
                                          Border.all(color: ds.colors.border),
                                    ),
                                    child: DSText(c.name,
                                        role: DSTextRole.caption,
                                        color: _category?.id == c.id
                                            ? const Color(0xFFFFFFFF)
                                            : ds.colors.textPrimary),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: ds.spacing.md),
                          _label(t('الوصف', 'Description')),
                          _ExpInput(controller: _desc),
                          SizedBox(height: ds.spacing.md),
                          _label(t('اسم المستفيد', 'Beneficiary')),
                          _ExpInput(controller: _vendor),
                          SizedBox(height: ds.spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label(t('المبلغ قبل الضريبة', 'Amount')),
                                    _ExpInput(
                                        controller: _before,
                                        number: true,
                                        onChanged: (_) => setState(() {})),
                                  ],
                                ),
                              ),
                              SizedBox(width: ds.spacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label(t('الضريبة', 'VAT')),
                                    _ExpInput(
                                        controller: _vat,
                                        number: true,
                                        onChanged: (_) => setState(() {})),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ds.spacing.sm),
                          DSText(
                            '${t('الإجمالي', 'Total')}: ${_total.toStringAsFixed(3)}',
                            role: DSTextRole.title,
                            color: ds.colors.primary,
                          ),
                          SizedBox(height: ds.spacing.md),
                          _label(t('طريقة الدفع', 'Payment method')),
                          Wrap(
                            spacing: ds.spacing.xs,
                            children: [
                              for (final pm in const [
                                ['cash', 'نقدي', 'Cash'],
                                ['bank', 'تحويل', 'Bank'],
                                ['card', 'بطاقة', 'Card'],
                              ])
                                GestureDetector(
                                  onTap: () => setState(() => _payment = pm[0]),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: EdgeInsetsDirectional.symmetric(
                                        horizontal: ds.spacing.md,
                                        vertical: ds.spacing.xs),
                                    decoration: BoxDecoration(
                                      color: _payment == pm[0]
                                          ? ds.colors.primary
                                          : ds.colors.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(ds.radii.pill),
                                      border:
                                          Border.all(color: ds.colors.border),
                                    ),
                                    child: DSText(isAr ? pm[1] : pm[2],
                                        role: DSTextRole.caption,
                                        color: _payment == pm[0]
                                            ? const Color(0xFFFFFFFF)
                                            : ds.colors.textPrimary),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: ds.spacing.md),
                          if (_message != null) ...[
                            DSText(_message!,
                                role: DSTextRole.caption,
                                color: _ok
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444)),
                            SizedBox(height: ds.spacing.sm),
                          ],
                          DSButton(
                            label: _submitting
                                ? t('جارٍ الحفظ...', 'Saving...')
                                : t('تسجيل المصروف', 'Record Expense'),
                            onPressed: _submitting ? null : _submit,
                            expanded: true,
                            size: DSButtonSize.large,
                          ),
                          SizedBox(height: ds.spacing.xl),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String s) {
    final ds = DSProvider.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: ds.spacing.xs),
      child: DSText(s, role: DSTextRole.caption, color: ds.colors.textSecondary),
    );
  }
}

class _ExpInput extends StatefulWidget {
  final TextEditingController controller;
  final bool number;
  final bool multiline;
  final ValueChanged<String>? onChanged;

  const _ExpInput({
    required this.controller,
    this.number = false,
    this.multiline = false,
    this.onChanged,
  });

  @override
  State<_ExpInput> createState() => _ExpInputState();
}

class _ExpInputState extends State<_ExpInput> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md, vertical: ds.spacing.sm),
      decoration: BoxDecoration(
        color: ds.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(ds.radii.medium),
        border: Border.all(color: ds.colors.border, width: 1.2),
      ),
      child: EditableText(
        controller: widget.controller,
        focusNode: _focus,
        style: ds.typography.body.copyWith(color: ds.colors.textPrimary),
        cursorColor: ds.colors.primary,
        backgroundCursorColor: ds.colors.textMuted,
        keyboardType: widget.number
            ? const TextInputType.numberWithOptions(decimal: true)
            : (widget.multiline ? TextInputType.multiline : TextInputType.text),
        maxLines: widget.multiline ? 3 : 1,
        minLines: widget.multiline ? 2 : 1,
        onChanged: widget.onChanged,
        textAlign:
            ds.textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
