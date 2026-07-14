import 'package:equatable/equatable.dart';

/// Appointment model matching Laravel's Appointment model
class Appointment extends Equatable {
  final int id;
  final int? patientId;
  final String? patientName;
  final String? patientPhone;
  final DateTime appointmentDate;
  final String? startTime;
  final String? endTime;
  final String status; // booked, checked_in, completed, cancelled
  final String? locationNotes;
  final String? serviceName;
  final String? departmentName;
  final int? sessionNo;
  final int? sessionDurationMinutes;
  final int? treatmentPlanId;

  const Appointment({
    required this.id,
    this.patientId,
    this.patientName,
    this.patientPhone,
    required this.appointmentDate,
    this.startTime,
    this.endTime,
    required this.status,
    this.locationNotes,
    this.serviceName,
    this.departmentName,
    this.sessionNo,
    this.sessionDurationMinutes,
    this.treatmentPlanId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      patientId: json['patient']?['id'] as int?,
      patientName: json['patient']?['name'] as String?,
      patientPhone: json['patient']?['phone'] as String?,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: json['status'] as String? ?? 'booked',
      locationNotes: json['location_notes'] as String?,
      serviceName: json['service']?['name'] as String?,
      departmentName: json['department']?['name'] as String?,
      sessionNo: json['session_no'] as int?,
      sessionDurationMinutes: json['session_duration_minutes'] as int?,
      treatmentPlanId: json['treatment_plan_id'] as int?,
    );
  }

  bool get isUpcoming => status == 'booked';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [id, appointmentDate, status];
}
