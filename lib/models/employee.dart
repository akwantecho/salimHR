import 'package:equatable/equatable.dart';

/// Employee model matching Laravel's Employee model
class Employee extends Equatable {
  final int id;
  final int userId;
  final int? departmentId;
  final String? jobTitle;
  final String? employeeType;
  final double? baseSalary;
  final DateTime? hiredAt;
  final String? status;
  final String? name;
  final String? email;
  final String? phone;
  final String? departmentName;

  const Employee({
    required this.id,
    required this.userId,
    this.departmentId,
    this.jobTitle,
    this.employeeType,
    this.baseSalary,
    this.hiredAt,
    this.status,
    this.name,
    this.email,
    this.phone,
    this.departmentName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      departmentId: json['department_id'] as int?,
      jobTitle: json['job_title'] as String?,
      employeeType: json['employee_type'] as String?,
      baseSalary: (json['base_salary'] as num?)?.toDouble(),
      hiredAt: json['hired_at'] != null
          ? DateTime.parse(json['hired_at'] as String)
          : null,
      status: json['status'] as String?,
      name: json['name'] as String? ?? json['user']?['name'] as String?,
      email: json['email'] as String? ?? json['user']?['email'] as String?,
      phone: json['phone'] as String? ?? json['user']?['phone'] as String?,
      departmentName: json['department']?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'department_id': departmentId,
    'job_title': jobTitle,
    'employee_type': employeeType,
    'base_salary': baseSalary,
    'hired_at': hiredAt?.toIso8601String(),
    'status': status,
  };

  @override
  List<Object?> get props => [id, userId, departmentId, jobTitle, employeeType, baseSalary];
}
