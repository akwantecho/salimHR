import 'package:equatable/equatable.dart';

/// Patient profile returned by GET /api/patients/{id}.
class Patient extends Equatable {
  final int id;
  final String? fileNumber;
  final String name;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;
  final int? age;
  final bool isChild;
  final String? guardianName;
  final String? guardianPhone;
  final String? nationality;
  final String? civilId;
  final String? address;
  final String? workplace;
  final String? notes;
  final bool isActive;
  final String? region;
  final String? city;
  final PatientDiagnosis? diagnosisCode;

  const Patient({
    required this.id,
    this.fileNumber,
    required this.name,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.age,
    this.isChild = false,
    this.guardianName,
    this.guardianPhone,
    this.nationality,
    this.civilId,
    this.address,
    this.workplace,
    this.notes,
    this.isActive = true,
    this.region,
    this.city,
    this.diagnosisCode,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      fileNumber: json['file_number']?.toString(),
      name: (json['name'] as String?) ?? '',
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      age: json['age'] as int?,
      isChild: json['is_child'] as bool? ?? false,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      nationality: json['nationality'] as String?,
      civilId: json['civil_id']?.toString(),
      address: json['address'] as String?,
      workplace: json['workplace'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      region: json['region'] as String?,
      city: json['city'] as String?,
      diagnosisCode: json['diagnosis_code'] != null
          ? PatientDiagnosis.fromJson(
              json['diagnosis_code'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, fileNumber];
}

/// ICD-style diagnosis attached to the patient file.
class PatientDiagnosis extends Equatable {
  final int id;
  final String? code;
  final String? title;

  const PatientDiagnosis({required this.id, this.code, this.title});

  factory PatientDiagnosis.fromJson(Map<String, dynamic> json) =>
      PatientDiagnosis(
        id: json['id'] as int,
        code: json['code'] as String?,
        title: json['title'] as String?,
      );

  @override
  List<Object?> get props => [id, code, title];
}

/// A single row of the patient's appointment history
/// (GET /api/patients/{id}/appointments).
class PatientVisit extends Equatable {
  final int id;
  final String? appointmentDate;
  final String? startTime;
  final String status;
  final int? sessionNo;
  final String? serviceName;
  final String? departmentName;

  const PatientVisit({
    required this.id,
    this.appointmentDate,
    this.startTime,
    required this.status,
    this.sessionNo,
    this.serviceName,
    this.departmentName,
  });

  factory PatientVisit.fromJson(Map<String, dynamic> json) => PatientVisit(
        id: json['id'] as int,
        appointmentDate: json['appointment_date'] as String?,
        startTime: json['start_time'] as String?,
        status: json['status'] as String? ?? 'booked',
        sessionNo: json['session_no'] as int?,
        serviceName: json['service']?['name'] as String?,
        departmentName: json['department']?['name'] as String?,
      );

  @override
  List<Object?> get props => [id, appointmentDate, status];
}

/// Metadata for an uploaded patient document
/// (GET /api/patients/{id}/documents).
class PatientDocumentInfo extends Equatable {
  final int id;
  final String? category;
  final String? title;
  final String? originalName;
  final String? mimeType;
  final bool isImage;
  final String? readableSize;
  final String? createdAt;

  const PatientDocumentInfo({
    required this.id,
    this.category,
    this.title,
    this.originalName,
    this.mimeType,
    this.isImage = false,
    this.readableSize,
    this.createdAt,
  });

  factory PatientDocumentInfo.fromJson(Map<String, dynamic> json) =>
      PatientDocumentInfo(
        id: json['id'] as int,
        category: json['category'] as String?,
        title: json['title'] as String?,
        originalName: json['original_name'] as String?,
        mimeType: json['mime_type'] as String?,
        isImage: json['is_image'] as bool? ?? false,
        readableSize: json['readable_size'] as String?,
        createdAt: json['created_at'] as String?,
      );

  String get displayName =>
      (title != null && title!.isNotEmpty) ? title! : (originalName ?? '#$id');

  @override
  List<Object?> get props => [id, originalName];
}
