import 'package:equatable/equatable.dart';

/// Treatment plan detail returned by GET /api/treatment-plans/{id}.
class TreatmentPlanDetail extends Equatable {
  final int id;
  final String status;
  final String? startDate;
  final String? scheduleType;
  final String? pattern;
  final bool isHomeVisit;
  final String? notes;
  final String? patientName;
  final String? patientPhone;
  final String? departmentName;
  final int? totalSessions;
  final int? freeSessions;
  final num? totalAmount;
  final String? currency;
  final int sessionsCount;
  final List<TreatmentSession> sessions;

  const TreatmentPlanDetail({
    required this.id,
    required this.status,
    this.startDate,
    this.scheduleType,
    this.pattern,
    this.isHomeVisit = false,
    this.notes,
    this.patientName,
    this.patientPhone,
    this.departmentName,
    this.totalSessions,
    this.freeSessions,
    this.totalAmount,
    this.currency,
    this.sessionsCount = 0,
    this.sessions = const [],
  });

  factory TreatmentPlanDetail.fromJson(Map<String, dynamic> json) {
    final sessions = (json['sessions'] as List<dynamic>? ?? [])
        .map((e) => TreatmentSession.fromJson(e as Map<String, dynamic>))
        .toList();
    return TreatmentPlanDetail(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'draft',
      startDate: json['start_date'] as String?,
      scheduleType: json['schedule_type'] as String?,
      pattern: json['pattern'] as String?,
      isHomeVisit: json['is_home_visit'] as bool? ?? false,
      notes: json['notes'] as String?,
      patientName: json['patient']?['name'] as String?,
      patientPhone: json['patient']?['phone'] as String?,
      departmentName: json['department']?['name'] as String?,
      totalSessions: json['package']?['total_sessions'] as int?,
      freeSessions: json['package']?['free_sessions'] as int?,
      totalAmount: json['pricing']?['total_amount'] as num?,
      currency: json['pricing']?['currency'] as String?,
      sessionsCount: json['sessions_count'] as int? ?? sessions.length,
      sessions: sessions,
    );
  }

  @override
  List<Object?> get props => [id, status, sessionsCount];
}

/// One session of a treatment plan.
class TreatmentSession extends Equatable {
  final int id;
  final int? sessionNo;
  final String status;
  final String? plannedDate;
  final bool isMakeup;
  final String? appointmentStatus;
  final String? appointmentDate;
  final String? appointmentStartTime;

  const TreatmentSession({
    required this.id,
    this.sessionNo,
    required this.status,
    this.plannedDate,
    this.isMakeup = false,
    this.appointmentStatus,
    this.appointmentDate,
    this.appointmentStartTime,
  });

  factory TreatmentSession.fromJson(Map<String, dynamic> json) {
    final appt = json['appointment'] as Map<String, dynamic>?;
    return TreatmentSession(
      id: json['id'] as int,
      sessionNo: json['session_no'] as int?,
      status: json['status'] as String? ?? 'planned',
      plannedDate: json['planned_date'] as String?,
      isMakeup: json['is_makeup'] as bool? ?? false,
      appointmentStatus: appt?['status'] as String?,
      appointmentDate: appt?['appointment_date'] as String?,
      appointmentStartTime: appt?['start_time'] as String?,
    );
  }

  /// A session can be edited only while still pending.
  bool get isPending =>
      status == 'planned' || status == 'scheduled';

  @override
  List<Object?> get props => [id, status, plannedDate];
}
