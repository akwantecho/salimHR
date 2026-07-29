// Models for the Reception (front desk) role.

class Patient {
  final int id;
  final String name;
  final String? phone;
  final String? gender;
  final String? fileNumber;
  final String? nationality;

  const Patient({
    required this.id,
    required this.name,
    this.phone,
    this.gender,
    this.fileNumber,
    this.nationality,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as int,
      name: json['name'] as String? ?? '-',
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      fileNumber: json['file_number'] as String?,
      nationality: json['nationality'] as String?,
    );
  }
}

class NamedRef {
  final int id;
  final String name;

  const NamedRef({required this.id, required this.name});

  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      NamedRef(id: json['id'] as int, name: json['name'] as String? ?? '-');
}

class ServiceOption {
  final int id;
  final String name;
  final int durationMinutes;

  const ServiceOption({
    required this.id,
    required this.name,
    this.durationMinutes = 30,
  });

  factory ServiceOption.fromJson(Map<String, dynamic> json) => ServiceOption(
    id: json['id'] as int,
    name: json['name'] as String? ?? '-',
    durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 30,
  );
}

/// One invoice row for the manager's invoices overview.
class InvoiceItem {
  final int id;
  final String? number;
  final DateTime? date;
  final String status;
  final String? type;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? patient;

  const InvoiceItem({
    required this.id,
    this.number,
    this.date,
    required this.status,
    this.type,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.patient,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    double money(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('${v ?? ''}') ?? 0;
    }

    return InvoiceItem(
      id: json['id'] as int,
      number: json['invoice_number'] as String?,
      date: json['invoice_date'] != null
          ? DateTime.tryParse(json['invoice_date'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      type: json['type'] as String?,
      totalAmount: money(json['total_amount']),
      paidAmount: money(json['paid_amount']),
      remainingAmount: money(json['remaining_amount']),
      patient: json['patient'] as String?,
    );
  }
}

/// A staff member for the manager's staff directory.
class StaffMember {
  final int id;
  final String name;
  final String? jobTitle;
  final String? type;
  final String? status;
  final String? department;
  final int todayAppointments;
  final bool hasAccount;
  final bool accessEnabled;

  const StaffMember({
    required this.id,
    required this.name,
    this.jobTitle,
    this.type,
    this.status,
    this.department,
    this.todayAppointments = 0,
    this.hasAccount = false,
    this.accessEnabled = false,
  });

  StaffMember copyWith({bool? accessEnabled}) => StaffMember(
    id: id,
    name: name,
    jobTitle: jobTitle,
    type: type,
    status: status,
    department: department,
    todayAppointments: todayAppointments,
    hasAccount: hasAccount,
    accessEnabled: accessEnabled ?? this.accessEnabled,
  );

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as int,
      name: json['name'] as String? ?? '-',
      jobTitle: json['job_title'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      department: json['department'] as String?,
      todayAppointments: (json['today_appointments'] as num?)?.toInt() ?? 0,
      hasAccount: json['has_account'] as bool? ?? false,
      accessEnabled: json['access_enabled'] as bool? ?? false,
    );
  }
}

class ReceptionAppointment {
  final int id;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String status;
  final bool isHomeVisit;
  final Patient? patient;
  final String? specialistName;
  final String? serviceName;
  final String? departmentName;

  /// Treatment room chosen by the specialist (read-only info elsewhere).
  final int? roomNumber;

  const ReceptionAppointment({
    required this.id,
    this.date,
    this.startTime,
    this.endTime,
    required this.status,
    this.isHomeVisit = false,
    this.patient,
    this.specialistName,
    this.serviceName,
    this.departmentName,
    this.roomNumber,
  });

  factory ReceptionAppointment.fromJson(Map<String, dynamic> json) {
    return ReceptionAppointment(
      id: json['id'] as int,
      date: json['appointment_date'] != null
          ? DateTime.tryParse(json['appointment_date'] as String)
          : null,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: json['status'] as String? ?? 'booked',
      isHomeVisit: json['is_home_visit'] as bool? ?? false,
      patient: json['patient'] != null
          ? Patient.fromJson(json['patient'] as Map<String, dynamic>)
          : null,
      specialistName: json['specialist']?['name'] as String?,
      serviceName: json['service']?['name'] as String?,
      departmentName: json['department']?['name'] as String?,
      roomNumber: (json['room_number'] as num?)?.toInt(),
    );
  }
}
