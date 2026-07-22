import 'package:equatable/equatable.dart';

/// One specialist's status for acknowledging today's session schedule.
///
/// API-ready: maps a row from `GET /api/hr/schedule-acknowledgements` so the
/// admin dashboard can show who has reviewed today's sessions and when.
class ScheduleAcknowledgement extends Equatable {
  final int specialistId;
  final String specialistName;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final int sessionsCount;

  const ScheduleAcknowledgement({
    required this.specialistId,
    required this.specialistName,
    required this.acknowledged,
    this.acknowledgedAt,
    this.sessionsCount = 0,
  });

  factory ScheduleAcknowledgement.fromJson(Map<String, dynamic> json) {
    final at = json['acknowledged_at'] as String?;
    return ScheduleAcknowledgement(
      specialistId: json['specialist_id'] as int? ?? json['id'] as int? ?? 0,
      specialistName:
          json['specialist']?['name'] as String? ??
          json['name'] as String? ??
          '',
      acknowledged: json['acknowledged'] as bool? ?? at != null,
      acknowledgedAt: at != null ? DateTime.tryParse(at) : null,
      sessionsCount: (json['sessions_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [specialistId, acknowledged, acknowledgedAt];
}
