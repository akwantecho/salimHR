import 'package:equatable/equatable.dart';

/// Parses a money/number value that the API may return as either a number
/// (e.g. 20.0) or a string (Laravel serializes DECIMAL columns as "20.000").
double moneyToDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

/// Payroll run status
enum PayrollStatus {
  draft,
  pendingApproval,
  approved,
  locked,
}

/// Payroll run model
class PayrollRun extends Equatable {
  final int id;
  final int clinicId;
  final int month;
  final int year;
  final PayrollStatus status;
  final double totalAmount;
  final int employeeCount;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final List<PayrollItem>? items;

  const PayrollRun({
    required this.id,
    required this.clinicId,
    required this.month,
    required this.year,
    required this.status,
    required this.totalAmount,
    required this.employeeCount,
    this.submittedAt,
    this.approvedAt,
    this.lockedAt,
    required this.createdAt,
    this.items,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    return PayrollRun(
      id: json['id'] as int,
      clinicId: json['clinic_id'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      status: _parseStatus(json['status'] as String),
      totalAmount: moneyToDouble(json['total_amount']),
      employeeCount: json['employee_count'] as int? ?? 0,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      lockedAt: json['locked_at'] != null
          ? DateTime.parse(json['locked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PayrollItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static PayrollStatus _parseStatus(String status) {
    switch (status) {
      case 'pending_approval':
        return PayrollStatus.pendingApproval;
      case 'approved':
        return PayrollStatus.approved;
      case 'locked':
        return PayrollStatus.locked;
      default:
        return PayrollStatus.draft;
    }
  }

  String get periodName => '$month/$year';

  @override
  List<Object?> get props => [id, clinicId, month, year, status, totalAmount];
}

/// Individual payroll item for an employee
class PayrollItem extends Equatable {
  final int id;
  final int payrollRunId;
  final int employeeId;
  final double baseSalary;
  final double allowances;
  final double bonuses;
  final double deductions;
  final double netSalary;
  final String? employeeName;
  final String? notes;
  final int? month;
  final int? year;

  const PayrollItem({
    required this.id,
    required this.payrollRunId,
    required this.employeeId,
    required this.baseSalary,
    required this.allowances,
    required this.bonuses,
    required this.deductions,
    required this.netSalary,
    this.employeeName,
    this.notes,
    this.month,
    this.year,
  });

  factory PayrollItem.fromJson(Map<String, dynamic> json) {
    return PayrollItem(
      id: json['id'] as int,
      payrollRunId: json['payroll_run_id'] as int,
      employeeId: json['employee_id'] as int,
      baseSalary: moneyToDouble(json['base_salary']),
      allowances: moneyToDouble(json['allowances']),
      bonuses: moneyToDouble(json['bonuses']),
      deductions: moneyToDouble(json['deductions']),
      netSalary: moneyToDouble(json['net_salary']),
      employeeName: json['employee']?['user']?['name'] as String?,
      notes: json['notes'] as String?,
      month: (json['month'] ?? json['payroll_run']?['month']) as int?,
      year: (json['year'] ?? json['payroll_run']?['year']) as int?,
    );
  }

  @override
  List<Object?> get props => [id, payrollRunId, employeeId, netSalary];
}

/// Employee bonus/deduction record
class EmployeeBonus extends Equatable {
  final int id;
  final int employeeId;
  final String type; // 'bonus' or 'deduction'
  final double amount;
  final String? reason;
  final int month;
  final int year;
  final DateTime createdAt;

  const EmployeeBonus({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.amount,
    this.reason,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  factory EmployeeBonus.fromJson(Map<String, dynamic> json) {
    return EmployeeBonus(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      type: (json['bonus_type'] ?? json['type']) as String,
      amount: moneyToDouble(json['amount']),
      reason: json['reason'] as String?,
      month: (json['period_month'] ?? json['month']) as int,
      year: (json['period_year'] ?? json['year']) as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isBonus => type == 'bonus';
  bool get isDeduction => type == 'deduction';

  @override
  List<Object?> get props => [id, employeeId, type, amount, month, year];
}
