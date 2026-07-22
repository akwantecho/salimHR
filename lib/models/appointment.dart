import 'package:equatable/equatable.dart';

/// Appointment model matching Laravel's Appointment model
class Appointment extends Equatable {
  final int id;
  final String? patientName;
  final String? patientPhone;
  final String? patientFileNo;
  final String? patientGender; // 'male' or 'female'
  final String? icdCode;
  final String? icdTitle;
  final DateTime appointmentDate;
  final String? startTime;
  final String? endTime;
  final String status; // booked, checked_in, completed, cancelled
  final String? locationNotes;
  final String? serviceName;
  final String? departmentName;
  final int? sessionNo;
  final int? sessionsTotal;
  final int? sessionDurationMinutes;
  final String? sessionType; // 'home' or 'center'

  const Appointment({
    required this.id,
    this.patientName,
    this.patientPhone,
    this.patientFileNo,
    this.patientGender,
    this.icdCode,
    this.icdTitle,
    required this.appointmentDate,
    this.startTime,
    this.endTime,
    required this.status,
    this.locationNotes,
    this.serviceName,
    this.departmentName,
    this.sessionNo,
    this.sessionsTotal,
    this.sessionDurationMinutes,
    this.sessionType,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      patientName: json['patient']?['name'] as String?,
      patientPhone: json['patient']?['phone'] as String?,
      patientFileNo:
          (json['patient']?['file_no'] ?? json['patient']?['mrn'])?.toString(),
      patientGender: json['patient']?['gender'] as String?,
      icdCode: (json['icd_code'] ?? json['diagnosis']?['icd_code']) as String?,
      icdTitle: (json['icd_title'] ?? json['diagnosis']?['title']) as String?,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: json['status'] as String? ?? 'booked',
      locationNotes: json['location_notes'] as String?,
      serviceName: json['service']?['name'] as String?,
      departmentName: json['department']?['name'] as String?,
      sessionNo: json['session_no'] as int?,
      sessionsTotal: json['sessions_total'] as int?,
      sessionDurationMinutes: json['session_duration_minutes'] as int?,
      sessionType: json['session_type'] as String?,
    );
  }

  bool get isUpcoming => status == 'booked';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  /// True when the session takes place at the patient's home.
  bool get isHomeVisit => sessionType == 'home';

  /// Progress label like "7/12" when session numbering is available.
  String? get sessionProgress {
    if (sessionNo == null) return null;
    if (sessionsTotal == null) return '$sessionNo';
    return '$sessionNo/$sessionsTotal';
  }

  @override
  List<Object?> get props => [id, appointmentDate, status];
}
