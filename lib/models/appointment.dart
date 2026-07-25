import 'package:equatable/equatable.dart';

/// Appointment model matching Laravel's Appointment model
class Appointment extends Equatable {
  final int id;
  final int? patientId;
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
  final int? roomNumber; // assigned treatment room (null = not chosen)

  const Appointment({
    required this.id,
    this.patientId,
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
    this.roomNumber,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      patientId: (json['patient']?['id'] as num?)?.toInt(),
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
      roomNumber: (json['room_number'] as num?)?.toInt(),
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
  List<Object?> get props => [id, appointmentDate, status, roomNumber];
}

/// Room availability for a single session's time slot, from
/// `GET /api/appointments/{id}/room-options`.
class RoomOptions {
  /// All selectable rooms (server-driven; defaults to 3–7).
  final List<int> rooms;

  /// room number → name of the specialist who already holds it this hour.
  final Map<int, String> taken;

  /// The room currently assigned to this appointment (null = none).
  final int? current;

  const RoomOptions({
    this.rooms = const [3, 4, 5, 6, 7],
    this.taken = const {},
    this.current,
  });

  factory RoomOptions.fromJson(Map<String, dynamic> json) {
    final rooms = (json['rooms'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const [3, 4, 5, 6, 7];

    final takenMap = <int, String>{};
    final raw = json['taken'];
    if (raw is List) {
      for (final t in raw) {
        if (t is Map) {
          final r = (t['room'] ?? t['room_number']) as num?;
          if (r != null) takenMap[r.toInt()] = (t['specialist'] ?? '').toString();
        }
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        final r = int.tryParse(k.toString());
        if (r != null) takenMap[r] = v.toString();
      });
    }

    return RoomOptions(
      rooms: rooms,
      taken: takenMap,
      current: (json['current'] as num?)?.toInt(),
    );
  }
}

/// Result of assigning/clearing a session's room. [conflict] is true when the
/// server rejected the room (409) because another specialist holds it this hour.
class RoomAssignResult {
  final bool success;
  final int? roomNumber;
  final bool conflict;
  final String? error;

  const RoomAssignResult({
    required this.success,
    this.roomNumber,
    this.conflict = false,
    this.error,
  });
}
