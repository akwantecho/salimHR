import 'package:equatable/equatable.dart';

/// Employee note model matching Laravel's EmployeeNote model
class EmployeeNote extends Equatable {
  final int id;
  final int? parentId;
  final int employeeId;
  final String? employeeName;
  final String note;
  final String visibility; // admin_to_employee or employee_to_admin
  final DateTime? readAt;
  final String? creatorName;
  final DateTime createdAt;

  /// Admin replies threaded under this note (empty for reply items themselves).
  final List<EmployeeNote> replies;

  const EmployeeNote({
    required this.id,
    this.parentId,
    required this.employeeId,
    this.employeeName,
    required this.note,
    required this.visibility,
    this.readAt,
    this.creatorName,
    required this.createdAt,
    this.replies = const [],
  });

  factory EmployeeNote.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? const [];
    return EmployeeNote(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      employeeId: json['employee_id'] as int,
      employeeName: json['employee']?['name'] as String?,
      note: json['note'] as String,
      visibility: json['visibility'] as String,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      creatorName: json['creator']?['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      replies: rawReplies
          .map((e) => EmployeeNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isIncoming => visibility == 'admin_to_employee';
  bool get isOutgoing => visibility == 'employee_to_admin';
  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, employeeId, visibility, createdAt];
}
