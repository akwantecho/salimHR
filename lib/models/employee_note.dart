import 'package:equatable/equatable.dart';

/// Employee note model matching Laravel's EmployeeNote model
class EmployeeNote extends Equatable {
  final int id;
  final int employeeId;
  final String note;
  final String visibility; // admin_to_employee or employee_to_admin
  final DateTime? readAt;
  final String? creatorName;
  final DateTime createdAt;

  const EmployeeNote({
    required this.id,
    required this.employeeId,
    required this.note,
    required this.visibility,
    this.readAt,
    this.creatorName,
    required this.createdAt,
  });

  factory EmployeeNote.fromJson(Map<String, dynamic> json) {
    return EmployeeNote(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      note: json['note'] as String,
      visibility: json['visibility'] as String,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      creatorName: json['creator']?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isIncoming => visibility == 'admin_to_employee';
  bool get isOutgoing => visibility == 'employee_to_admin';
  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, employeeId, visibility, createdAt];
}
