import 'package:equatable/equatable.dart';

/// Types of approvals in the system
enum ApprovalType {
  leave,
  medicalExcuse,
  inventory,
  payroll,
}

/// Status of an approval
enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

/// Base approval model for all approval types
class Approval extends Equatable {
  final int id;
  final ApprovalType type;
  final ApprovalStatus status;
  final String title;
  final String? description;
  final String? employeeName;
  final int? employeeId;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;

  const Approval({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    this.employeeName,
    this.employeeId,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.metadata,
  });

  factory Approval.fromJson(Map<String, dynamic> json, ApprovalType type) {
    return Approval(
      id: json['id'] as int,
      type: type,
      status: _parseStatus(json['status'] as String?),
      title: _generateTitle(json, type),
      description: json['notes'] as String? ?? json['reason'] as String?,
      employeeName: json['employee']?['name'] as String? ??
          json['employee']?['user']?['name'] as String?,
      employeeId: json['employee_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by']?['name'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      metadata: json,
    );
  }

  static ApprovalStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  static String _generateTitle(Map<String, dynamic> json, ApprovalType type) {
    switch (type) {
      case ApprovalType.leave:
        final leaveType = json['leave_type']?['name'] ?? 'Leave';
        return '$leaveType Request';
      case ApprovalType.medicalExcuse:
        return 'Medical Excuse';
      case ApprovalType.inventory:
        return 'Inventory Request #${json['id']}';
      case ApprovalType.payroll:
        final month = json['month'] ?? '';
        final year = json['year'] ?? '';
        return 'Payroll $month/$year';
    }
  }

  @override
  List<Object?> get props => [id, type, status, title, createdAt];
}

/// Leave request details
class LeaveRequest extends Equatable {
  final int id;
  final int employeeId;
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String? reason;
  final String status;
  final String? leaveTypeName;
  final String? employeeName;
  final int? totalDays;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    this.reason,
    required this.status,
    this.leaveTypeName,
    this.employeeName,
    this.totalDays,
    required this.createdAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      leaveTypeId: json['leave_type_id'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      reason: json['reason'] as String?,
      status: json['status'] as String,
      leaveTypeName: json['leave_type']?['name'] as String?,
      employeeName: json['employee']?['user']?['name'] as String?,
      totalDays: json['total_days'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, employeeId, leaveTypeId, startDate, endDate, status];
}

/// Medical excuse details
class MedicalExcuse extends Equatable {
  final int id;
  final int employeeId;
  final DateTime excuseDate;
  final String? hospitalName;
  final String? doctorName;
  final String? notes;
  final String status;
  final String? employeeName;
  final DateTime createdAt;

  const MedicalExcuse({
    required this.id,
    required this.employeeId,
    required this.excuseDate,
    this.hospitalName,
    this.doctorName,
    this.notes,
    required this.status,
    this.employeeName,
    required this.createdAt,
  });

  factory MedicalExcuse.fromJson(Map<String, dynamic> json) {
    return MedicalExcuse(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      excuseDate: DateTime.parse(json['excuse_date'] as String),
      hospitalName: json['hospital_name'] as String?,
      doctorName: json['doctor_name'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      employeeName: json['employee']?['user']?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, employeeId, excuseDate, status];
}
