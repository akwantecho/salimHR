import 'package:equatable/equatable.dart';

/// Today's attendance status — returned by `/api/employee/attendance/today`.
/// `checkInAt`/`checkOutAt` are null until the user records them.
class AttendanceToday extends Equatable {
  final DateTime date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? workedMinutes;

  const AttendanceToday({
    required this.date,
    this.checkInAt,
    this.checkOutAt,
    this.workedMinutes,
  });

  bool get hasCheckedIn => checkInAt != null;
  bool get hasCheckedOut => checkOutAt != null;
  bool get isComplete => hasCheckedIn && hasCheckedOut;

  factory AttendanceToday.fromJson(Map<String, dynamic> json) {
    return AttendanceToday(
      date: DateTime.parse(json['date'] as String),
      checkInAt: json['check_in_at'] != null
          ? DateTime.tryParse(json['check_in_at'] as String)
          : null,
      checkOutAt: json['check_out_at'] != null
          ? DateTime.tryParse(json['check_out_at'] as String)
          : null,
      workedMinutes: (json['worked_minutes'] as num?)?.toInt(),
    );
  }

  AttendanceToday copyWith({
    DateTime? checkInAt,
    DateTime? checkOutAt,
    int? workedMinutes,
  }) =>
      AttendanceToday(
        date: date,
        checkInAt: checkInAt ?? this.checkInAt,
        checkOutAt: checkOutAt ?? this.checkOutAt,
        workedMinutes: workedMinutes ?? this.workedMinutes,
      );

  @override
  List<Object?> get props => [date, checkInAt, checkOutAt, workedMinutes];
}

/// One day from the monthly attendance log.
class AttendanceDay extends Equatable {
  final String dateString;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final bool worked;
  final bool partial;
  final int? workedMinutes;
  final int sessionsCount;
  final int completedCount;

  const AttendanceDay({
    required this.dateString,
    this.checkInAt,
    this.checkOutAt,
    required this.worked,
    required this.partial,
    this.workedMinutes,
    required this.sessionsCount,
    required this.completedCount,
  });

  DateTime get date => DateTime.parse(dateString);

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    return AttendanceDay(
      dateString: json['date'] as String,
      checkInAt: json['check_in_at'] != null
          ? DateTime.tryParse(json['check_in_at'] as String)
          : null,
      checkOutAt: json['check_out_at'] != null
          ? DateTime.tryParse(json['check_out_at'] as String)
          : null,
      worked: json['worked'] as bool? ?? false,
      partial: json['partial'] as bool? ?? false,
      workedMinutes: (json['worked_minutes'] as num?)?.toInt(),
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [dateString, checkInAt, checkOutAt, worked, partial];
}
