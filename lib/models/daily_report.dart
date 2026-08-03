import 'package:equatable/equatable.dart';

/// A short end-of-day report written by an employee (reception) describing the
/// day's events. Reaches the admin in a dedicated inbox where each report is
/// dated; the admin marks it read as proof they've seen it, which notifies the
/// author.
class DailyReport extends Equatable {
  final int id;
  final int? authorId;
  final String? authorName;
  final String content;

  /// The business day the report is about (server-stamped, YYYY-MM-DD).
  final DateTime reportDate;
  final DateTime createdAt;

  /// Set once the admin has acknowledged reading the report.
  final DateTime? readAt;
  final String? readByName;

  const DailyReport({
    required this.id,
    this.authorId,
    this.authorName,
    required this.content,
    required this.reportDate,
    required this.createdAt,
    this.readAt,
    this.readByName,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    DateTime parse(String? s, DateTime fallback) =>
        s != null ? DateTime.parse(s) : fallback;
    final created = parse(json['created_at'] as String?, DateTime(2000));
    return DailyReport(
      id: json['id'] as int,
      authorId: json['author_id'] as int? ?? json['employee_id'] as int?,
      authorName:
          json['author_name'] as String? ?? json['author']?['name'] as String?,
      content: (json['content'] ?? json['report'] ?? '') as String,
      reportDate: parse(
        json['report_date'] as String? ?? json['date'] as String?,
        created,
      ),
      createdAt: created,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      readByName:
          json['read_by_name'] as String? ?? json['read_by']?['name'] as String?,
    );
  }

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, readAt];
}
