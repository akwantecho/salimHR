import 'package:flutter/widgets.dart';

import '../../design_system/components/line_icons.dart';
import '../../design_system/ds_provider.dart';
import '../../design_system/primitives/ds_text.dart';
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../i18n.dart';
import '../ui/blocks.dart';
import 'inventory_request_screen.dart';
import 'inventory_stocktake_screen.dart';

// ==================== WORKER HOME SCREEN ====================

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool _isLoading = true;
  String? _error;
  PayrollItem? _salary;
  List<InventoryRequest> _recentRequests = [];

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
      final user = context.authService.currentUser;
      final employeeId = user?.employeeId;
      final payrollService = context.payrollService;
      final inventoryService = context.inventoryService;

      // Fetch salary if employee is linked
      if (employeeId != null) {
        _salary = await payrollService.getEmployeeSalary(employeeId: employeeId);
      }

      // Fetch recent inventory requests
      await inventoryService.fetchMyRequests();
      if (!mounted) return;
      _recentRequests = inventoryService.myRequests.take(3).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      return _ErrorView(error: _error!, onRetry: _load);
    }

    final quickActions = [
      _QuickAction(
        label: t('تحديث مخزون', 'Update Stock'),
        icon: LineIconType.chart,
        color: const Color(0xFF6366F1),
      ),
      _QuickAction(
        label: t('طلب شراء', 'Purchase'),
        icon: LineIconType.calendar,
        color: const Color(0xFF10B981),
      ),
      _QuickAction(
        label: t('إجازة', 'Leave'),
        icon: LineIconType.bookmark,
        color: const Color(0xFFF59E0B),
      ),
      _QuickAction(
        label: t('عذر طبي', 'Medical'),
        icon: LineIconType.heart,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salary Summary Card
              _WorkerSalaryCard(salary: _salary),
              SizedBox(height: ds.spacing.lg),

              // Quick Actions
              SectionHeader(title: t('إجراءات سريعة', 'Quick Actions')),
              Row(
                children: [
                  for (int i = 0; i < quickActions.length; i++) ...[
                    if (i > 0) SizedBox(width: ds.spacing.sm),
                    Expanded(
                      child: _QuickActionCard(action: quickActions[i]),
                    ),
                  ],
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Recent Requests
              SectionHeader(
                title: t('آخر الطلبات', 'Recent Requests'),
                actionLabel: t('عرض الكل', 'View All'),
                onAction: () {},
              ),
            ],
          ),
        ),
        if (_recentRequests.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                child: DSText(
                  t('لا توجد طلبات', 'No requests yet'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final req = _recentRequests[index];
              final statusColor = _requestStatusColor(req.status);
              return RequestTile(
                title: t('طلب مخزون #${req.id}', 'Inventory Request #${req.id}'),
                subtitle: req.notes ?? t('${req.items?.length ?? 0} أصناف', '${req.items?.length ?? 0} items'),
                status: _requestStatusLabel(context, req.status),
                statusColor: statusColor,
              );
            },
            itemCount: _recentRequests.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

// ==================== INVENTORY SCREEN ====================

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';

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
      await context.inventoryService.fetchItems();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = context.inventoryService.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<InventoryItem> get _filteredItems {
    final service = context.inventoryService;
    switch (_filter) {
      case 'low':
        return service.filterByStatus('low');
      case 'out':
        return service.filterByStatus('out');
      case 'ok':
        return service.filterByStatus('ok');
      default:
        return service.items;
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
      return _ErrorView(error: _error!, onRetry: _load);
    }

    final service = context.inventoryService;
    final items = _filteredItems;

    Future<void> openSubAndRefresh(Widget Function(VoidCallback onBack) build) async {
      await Navigator.of(context).push<void>(
        PageRouteBuilder(
          pageBuilder: (ctx, _, _) => build(() => Navigator.of(ctx).pop()),
        ),
      );
      if (mounted) _load();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Action row — open the two new sub-screens
              Row(
                children: [
                  Expanded(
                    child: _InventoryActionCard(
                      label: t('طلب مخزون', 'New Request'),
                      sub: t('اطلب مواد جديدة', 'Request items'),
                      icon: LineIconType.bookmark,
                      color: const Color(0xFF6366F1),
                      onTap: () => openSubAndRefresh(
                        (onBack) => InventoryRequestScreen(onBack: onBack),
                      ),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _InventoryActionCard(
                      label: t('جرد المخزون', 'Stocktake'),
                      sub: t('عدّ المواد الفعلي', 'Physical count'),
                      icon: LineIconType.chart,
                      color: const Color(0xFF10B981),
                      onTap: () => openSubAndRefresh(
                        (onBack) => InventoryStocktakeScreen(onBack: onBack),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              // Summary Stats
              Row(
                children: [
                  Expanded(
                    child: _InventoryStatCard(
                      title: t('إجمالي الأصناف', 'Total Items'),
                      value: '${service.totalItems}',
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _InventoryStatCard(
                      title: t('مخزون منخفض', 'Low Stock'),
                      value: '${service.lowStockCount}',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(width: ds.spacing.sm),
                  Expanded(
                    child: _InventoryStatCard(
                      title: t('نفذ', 'Out'),
                      value: '${service.outOfStockCount}',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ds.spacing.lg),

              SectionHeader(
                title: t('المخزون', 'Inventory'),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _filter = 'all'),
                      child: _InventoryFilterChip(
                        label: t('الكل', 'All'),
                        isSelected: _filter == 'all',
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => setState(() => _filter = 'low'),
                      child: _InventoryFilterChip(
                        label: t('منخفض', 'Low'),
                        isSelected: _filter == 'low',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => setState(() => _filter = 'ok'),
                      child: _InventoryFilterChip(
                        label: t('جيد', 'Good'),
                        isSelected: _filter == 'ok',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(width: ds.spacing.sm),
                    GestureDetector(
                      onTap: () => setState(() => _filter = 'out'),
                      child: _InventoryFilterChip(
                        label: t('نفذ', 'Out'),
                        isSelected: _filter == 'out',
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.md),
            ],
          ),
        ),
        if (items.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                child: DSText(
                  t('لا توجد أصناف', 'No items found'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) => _InventoryCard(item: items[index]),
            itemCount: items.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

// ==================== WORKER REQUESTS SCREEN ====================

class WorkerRequestsScreen extends StatefulWidget {
  const WorkerRequestsScreen({super.key});

  @override
  State<WorkerRequestsScreen> createState() => _WorkerRequestsScreenState();
}

class _WorkerRequestsScreenState extends State<WorkerRequestsScreen> {
  bool _isLoading = true;
  String? _error;

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
      await context.inventoryService.fetchMyRequests();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = context.inventoryService.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      return _ErrorView(error: _error!, onRetry: _load);
    }

    final requests = context.inventoryService.myRequests;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: t('طلباتي', 'My Requests'),
          ),
        ),
        if (requests.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                child: DSText(
                  t('لا توجد طلبات', 'No requests yet'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final req = requests[index];
              final statusColor = _requestStatusColor(req.status);
              final itemsSummary = req.items != null && req.items!.isNotEmpty
                  ? req.items!.map((i) => '${i.itemName ?? t('صنف', 'Item')} x${i.quantity}').join(', ')
                  : req.notes ?? t('طلب #${req.id}', 'Request #${req.id}');
              return RequestTile(
                title: t('طلب مخزون #${req.id}', 'Inventory Request #${req.id}'),
                subtitle: itemsSummary,
                status: _requestStatusLabel(context, req.status),
                statusColor: statusColor,
              );
            },
            itemCount: requests.length,
            spacing: ds.spacing.sm,
          ),
      ],
    );
  }
}

// ==================== SALARY SCREEN ====================

class SalaryScreen extends StatefulWidget {
  final bool showPercent;

  const SalaryScreen({super.key, this.showPercent = false});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  bool _isLoading = true;
  String? _error;
  PayrollItem? _currentSalary;
  List<PayrollItem> _history = [];

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
      final user = context.authService.currentUser;
      final employeeId = user?.employeeId;

      if (employeeId != null) {
        final payrollService = context.payrollService;
        _currentSalary = await payrollService.getEmployeeSalary(employeeId: employeeId);
        _history = await payrollService.getPaymentHistory(employeeId);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      return _ErrorView(error: _error!, onRetry: _load);
    }

    final salary = _currentSalary;
    final net = salary?.netSalary ?? 0;
    final base = salary?.baseSalary ?? 0;
    final allowances = salary?.allowances ?? 0;
    final deductions = salary?.deductions ?? 0;

    final now = DateTime.now();
    final months = _monthNames(context);
    final monthName = months[now.month - 1];
    final periodLabel = '$monthName ${now.year}';

    final breakdown = [
      _SalaryLineData(
        title: t('راتب أساسي', 'Base Salary'),
        value: _formatCurrency(context, base),
        color: const Color(0xFF6366F1),
        icon: LineIconType.bookmark,
      ),
      if (allowances > 0)
        _SalaryLineData(
          title: t('بدلات', 'Allowances'),
          value: '+${_formatCurrency(context, allowances)}',
          color: const Color(0xFF10B981),
          icon: LineIconType.heart,
        ),
      if (deductions > 0)
        _SalaryLineData(
          title: t('خصومات', 'Deductions'),
          value: '-${_formatCurrency(context, deductions)}',
          color: const Color(0xFFEF4444),
          icon: LineIconType.calendar,
        ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Salary Card
              Container(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ds.radii.xLarge),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DSText(
                          t('صافي الراتب', 'Net Salary'),
                          role: DSTextRole.caption,
                          color: const Color(0xFFFFFFFF).withOpacity(0.9),
                        ),
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: ds.spacing.sm,
                            vertical: ds.spacing.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(ds.radii.pill),
                          ),
                          child: DSText(
                            periodLabel,
                            role: DSTextRole.caption,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ds.spacing.sm),
                    DSText(
                      _formatCurrency(context, net),
                      role: DSTextRole.display,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ds.spacing.lg),

              // Breakdown Section
              SectionHeader(title: t('تفاصيل الراتب', 'Salary Breakdown')),
            ],
          ),
        ),
        SliverSeparatedList(
          itemBuilder: (context, index) => _SalaryLineCard(data: breakdown[index]),
          itemCount: breakdown.length,
          spacing: ds.spacing.sm,
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ds.spacing.lg),

              // Payment History
              SectionHeader(
                title: t('سجل المدفوعات', 'Payment History'),
              ),
            ],
          ),
        ),
        if (_history.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsetsDirectional.all(ds.spacing.lg),
                child: DSText(
                  t('لا يوجد سجل مدفوعات', 'No payment history'),
                  role: DSTextRole.caption,
                  color: ds.colors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverSeparatedList(
            itemBuilder: (context, index) {
              final item = _history[index];
              final label = item.employeeName ?? '';
              return _PaymentHistoryCard(
                month: label,
                amount: _formatCurrency(context, item.netSalary),
                status: t('مدفوع', 'Paid'),
                color: const Color(0xFF10B981),
              );
            },
            itemCount: _history.length,
            spacing: ds.spacing.sm,
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: ds.spacing.lg),
        ),
      ],
    );
  }
}

// ==================== SHARED HELPERS ====================

Color _requestStatusColor(InventoryRequestStatus status) {
  switch (status) {
    case InventoryRequestStatus.pending:
      return const Color(0xFFF59E0B);
    case InventoryRequestStatus.approved:
      return const Color(0xFF10B981);
    case InventoryRequestStatus.rejected:
      return const Color(0xFFEF4444);
    case InventoryRequestStatus.fulfilled:
      return const Color(0xFF6366F1);
  }
}

String _requestStatusLabel(BuildContext context, InventoryRequestStatus status) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  switch (status) {
    case InventoryRequestStatus.pending:
      return t('قيد المراجعة', 'Pending');
    case InventoryRequestStatus.approved:
      return t('مقبول', 'Approved');
    case InventoryRequestStatus.rejected:
      return t('مرفوض', 'Rejected');
    case InventoryRequestStatus.fulfilled:
      return t('تم التنفيذ', 'Fulfilled');
  }
}

String _formatCurrency(BuildContext context, double amount) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  final formatted = amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return t('$formatted ر.ع', 'OMR $formatted');
}

List<String> _monthNames(BuildContext context) {
  String t(String ar, String en) => tr(context, ar: ar, en: en);
  return [
    t('يناير', 'January'), t('فبراير', 'February'), t('مارس', 'March'),
    t('أبريل', 'April'), t('مايو', 'May'), t('يونيو', 'June'),
    t('يوليو', 'July'), t('أغسطس', 'August'), t('سبتمبر', 'September'),
    t('أكتوبر', 'October'), t('نوفمبر', 'November'), t('ديسمبر', 'December'),
  ];
}

// ==================== SHARED WIDGETS ====================

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
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
            error,
            role: DSTextRole.caption,
            color: ds.colors.textSecondary,
          ),
          SizedBox(height: ds.spacing.lg),
          GestureDetector(
            onTap: onRetry,
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
}

class _WorkerSalaryCard extends StatelessWidget {
  final PayrollItem? salary;

  const _WorkerSalaryCard({this.salary});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);

    final net = salary?.netSalary ?? 0;
    final base = salary?.baseSalary ?? 0;
    final allowances = salary?.allowances ?? 0;
    final deductions = salary?.deductions ?? 0;

    final months = _monthNames(context);
    final monthName = months[DateTime.now().month - 1];

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(ds.radii.xLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DSText(
                t('راتبي الشهري', 'My Monthly Salary'),
                role: DSTextRole.caption,
                color: const Color(0xFFFFFFFF).withOpacity(0.9),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ds.radii.small),
                ),
                child: DSText(
                  monthName,
                  role: DSTextRole.caption,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.sm),
          DSText(
            _formatCurrency(context, net),
            role: DSTextRole.display,
            color: const Color(0xFFFFFFFF),
          ),
          SizedBox(height: ds.spacing.md),
          Row(
            children: [
              _SalaryMiniStat(
                label: t('أساسي', 'Base'),
                value: base.toStringAsFixed(0),
              ),
              SizedBox(width: ds.spacing.md),
              _SalaryMiniStat(
                label: t('بدلات', 'Allowance'),
                value: '+${allowances.toStringAsFixed(0)}',
              ),
              SizedBox(width: ds.spacing.md),
              _SalaryMiniStat(
                label: t('خصومات', 'Deduct'),
                value: '-${deductions.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalaryMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _SalaryMiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          label,
          role: DSTextRole.caption,
          color: const Color(0xFFFFFFFF).withOpacity(0.7),
        ),
        DSText(
          value,
          role: DSTextRole.label,
          color: const Color(0xFFFFFFFF),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final LineIconType icon;
  final Color color;

  _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.sm),
      decoration: BoxDecoration(
        color: action.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(
          color: action.color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  action.color,
                  action.color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(ds.radii.medium),
              boxShadow: [
                BoxShadow(
                  color: action.color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: DSLineIcon(
                type: action.icon,
                color: const Color(0xFFFFFFFF),
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(height: ds.spacing.xs),
          DSText(
            action.label,
            role: DSTextRole.caption,
            color: action.color,
          ),
        ],
      ),
    );
  }
}

class _InventoryActionCard extends StatelessWidget {
  final String label;
  final String sub;
  final LineIconType icon;
  final Color color;
  final VoidCallback onTap;

  const _InventoryActionCard({
    required this.label,
    required this.sub,
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
        padding: EdgeInsetsDirectional.all(ds.spacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              color,
              Color.lerp(color, const Color(0xFF000000), 0.2)!,
            ],
          ),
          borderRadius: BorderRadius.circular(ds.radii.large),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: ds.spacing.xl,
              height: ds.spacing.xl,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DSLineIcon(
                  type: icon,
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
                  DSText(label,
                      role: DSTextRole.title,
                      color: const Color(0xFFFFFFFF),
                      maxLines: 1),
                  SizedBox(height: 2),
                  DSText(
                    sub,
                    role: DSTextRole.caption,
                    color: const Color(0xFFFFFFFF).withOpacity(0.85),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InventoryStatCard({
    required this.title,
    required this.value,
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
            value,
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

class _InventoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;

  const _InventoryFilterChip({
    required this.label,
    required this.isSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final chipColor = color ?? ds.colors.primary;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: ds.spacing.md,
        vertical: ds.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? chipColor.withOpacity(0.15) : ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.pill),
        border: Border.all(
          color: isSelected ? chipColor : ds.colors.border,
        ),
      ),
      child: DSText(
        label,
        role: DSTextRole.label,
        color: isSelected ? chipColor : ds.colors.textSecondary,
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    String t(String ar, String en) => tr(context, ar: ar, en: en);
    final minQty = item.minQuantity ?? 1;
    final percentage = minQty > 0 ? (item.quantity / minQty).clamp(0.0, 1.0) : 1.0;

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

    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
        boxShadow: [
          BoxShadow(
            color: itemColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    DSText(
                      item.name,
                      role: DSTextRole.title,
                    ),
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
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: ds.spacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ds.radii.small),
                ),
                child: DSText(
                  statusLabel,
                  role: DSTextRole.caption,
                  color: itemColor,
                ),
              ),
            ],
          ),
          SizedBox(height: ds.spacing.md),

          // Progress Bar
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
                    colors: [
                      itemColor,
                      itemColor.withOpacity(0.7),
                    ],
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

class _SalaryLineData {
  final String title;
  final String value;
  final Color color;
  final LineIconType icon;

  _SalaryLineData({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _SalaryLineCard extends StatelessWidget {
  final _SalaryLineData data;

  const _SalaryLineCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(
                type: data.icon,
                color: data.color,
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: DSText(
              data.title,
              role: DSTextRole.title,
            ),
          ),
          DSText(
            data.value,
            role: DSTextRole.label,
            color: data.color,
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final String month;
  final String amount;
  final String status;
  final Color color;

  const _PaymentHistoryCard({
    required this.month,
    required this.amount,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return Container(
      padding: EdgeInsetsDirectional.all(ds.spacing.md),
      decoration: BoxDecoration(
        color: ds.colors.surface,
        borderRadius: BorderRadius.circular(ds.radii.large),
        border: Border.all(color: ds.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: ds.spacing.xl,
            height: ds.spacing.xl,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ds.radii.medium),
            ),
            child: Center(
              child: DSLineIcon(
                type: LineIconType.calendar,
                color: color,
                size: ds.spacing.md,
              ),
            ),
          ),
          SizedBox(width: ds.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  month,
                  role: DSTextRole.title,
                ),
                SizedBox(height: ds.spacing.xs / 2),
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
                    status,
                    role: DSTextRole.caption,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          DSText(
            amount,
            role: DSTextRole.label,
            color: ds.colors.textPrimary,
          ),
        ],
      ),
    );
  }
}

