import 'package:equatable/equatable.dart';

/// HR Dashboard stats model matching Laravel's HRController dashboard response
class HRDashboard extends Equatable {
  final int totalEmployees;
  final int activeEmployees;
  final int onLeaveToday;
  final int pendingLeaves;
  final int pendingExcuses;
  final int pendingPayrolls;
  final double totalPayroll;
  final List<DashboardStat> recentStats;

  const HRDashboard({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.onLeaveToday,
    required this.pendingLeaves,
    required this.pendingExcuses,
    required this.pendingPayrolls,
    required this.totalPayroll,
    this.recentStats = const [],
  });

  factory HRDashboard.fromJson(Map<String, dynamic> json) {
    // Handle nested 'stats' structure from Laravel API
    final stats = json['stats'] as Map<String, dynamic>? ?? json;

    return HRDashboard(
      totalEmployees: stats['total_employees'] as int? ?? json['total_employees'] as int? ?? 0,
      activeEmployees: stats['active_employees'] as int? ?? stats['total_employees'] as int? ?? 0,
      onLeaveToday: stats['on_leave_today'] as int? ?? json['on_leave_today'] as int? ?? 0,
      pendingLeaves: stats['pending_leaves'] as int? ?? json['pending_leaves'] as int? ?? 0,
      pendingExcuses: stats['pending_excuses'] as int? ?? json['pending_excuses'] as int? ?? 0,
      pendingPayrolls: stats['pending_payrolls'] as int? ?? json['pending_payrolls'] as int? ?? 0,
      totalPayroll: (stats['total_payroll'] as num?)?.toDouble() ??
                    (json['total_payroll'] as num?)?.toDouble() ?? 0,
      recentStats: (json['recent_stats'] as List<dynamic>?)
          ?.map((e) => DashboardStat.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Total pending approvals
  int get totalPendingApprovals => pendingLeaves + pendingExcuses + pendingPayrolls;

  @override
  List<Object?> get props => [
    totalEmployees,
    activeEmployees,
    onLeaveToday,
    pendingLeaves,
    pendingExcuses,
    pendingPayrolls,
  ];
}

/// Individual stat item for dashboard
class DashboardStat extends Equatable {
  final String label;
  final String value;
  final String? change;
  final bool isPositive;

  const DashboardStat({
    required this.label,
    required this.value,
    this.change,
    this.isPositive = true,
  });

  factory DashboardStat.fromJson(Map<String, dynamic> json) {
    return DashboardStat(
      label: json['label'] as String,
      value: json['value'].toString(),
      change: json['change'] as String?,
      isPositive: json['is_positive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [label, value, change];
}

/// Leave type model
class LeaveType extends Equatable {
  final int id;
  final String name;
  final String? nameAr;
  final String? code;
  final String? color;
  final int? defaultDays;
  final int? maxDaysPerYear;
  final bool isPaid;
  final bool requiresApproval;
  final String? description;

  const LeaveType({
    required this.id,
    required this.name,
    this.nameAr,
    this.code,
    this.color,
    this.defaultDays,
    this.maxDaysPerYear,
    this.isPaid = true,
    this.requiresApproval = true,
    this.description,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] as int,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      code: json['code'] as String?,
      color: json['color'] as String?,
      defaultDays: json['default_days'] as int?,
      maxDaysPerYear: json['max_days_per_year'] as int?,
      isPaid: json['is_paid'] as bool? ?? true,
      requiresApproval: json['requires_approval'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  /// Localized display label — prefers Arabic when available, falls back to
  /// the English `name`.
  String displayName({bool preferArabic = true}) =>
      preferArabic ? (nameAr ?? name) : name;

  @override
  List<Object?> get props => [id, name];
}
