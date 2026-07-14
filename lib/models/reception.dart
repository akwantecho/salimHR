import 'package:equatable/equatable.dart';

/// An appointment as seen by the front desk (GET /api/reception/appointments).
/// Mirrors the backend `ReceptionAppointmentsController` transform.
class ReceptionAppointment extends Equatable {
  final int id;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String status;
  final bool isHomeVisit;
  final double? priceTotal;
  final int? sessionNo;
  final int? treatmentPlanId;
  final int? patientId;
  final String? patientName;
  final String? patientPhone;
  final String? serviceName;
  final int? durationMinutes;
  final String? specialistName;
  final String? departmentName;
  // Detail-only fields.
  final String? locationAddress;
  final String? noShowReason;

  const ReceptionAppointment({
    required this.id,
    this.date,
    this.startTime,
    this.endTime,
    this.status = 'booked',
    this.isHomeVisit = false,
    this.priceTotal,
    this.sessionNo,
    this.treatmentPlanId,
    this.patientId,
    this.patientName,
    this.patientPhone,
    this.serviceName,
    this.durationMinutes,
    this.specialistName,
    this.departmentName,
    this.locationAddress,
    this.noShowReason,
  });

  factory ReceptionAppointment.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    final specialist = json['specialist'] as Map<String, dynamic>?;
    final department = json['department'] as Map<String, dynamic>?;
    return ReceptionAppointment(
      id: json['id'] as int,
      date: json['appointment_date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: (json['status'] as String?) ?? 'booked',
      isHomeVisit: json['is_home_visit'] as bool? ?? false,
      priceTotal: (json['price_total'] as num?)?.toDouble(),
      sessionNo: json['session_no'] as int?,
      treatmentPlanId: json['treatment_plan_id'] as int?,
      patientId: patient?['id'] as int?,
      patientName: patient?['name'] as String?,
      patientPhone: patient?['phone'] as String?,
      serviceName: service?['name'] as String?,
      durationMinutes: service?['duration_minutes'] as int?,
      specialistName: specialist?['name'] as String?,
      departmentName: department?['name'] as String?,
      locationAddress: json['location_address'] as String?,
      noShowReason: json['no_show_reason'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, date, startTime, patientId];
}

/// A bookable time slot from GET /api/reception/appointments/slots.
class AppointmentSlot extends Equatable {
  final String start;
  final String? end;
  final bool available;

  const AppointmentSlot({required this.start, this.end, this.available = false});

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      start: (json['start'] as String?) ?? '',
      end: json['end'] as String?,
      available: json['available'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [start, end, available];
}

/// Pickers for the booking form (GET /api/reception/appointments/options).
class BookingOptions extends Equatable {
  final List<ServiceOption> services;
  final List<DepartmentOption> departments;
  final List<SpecialistOption> specialists;
  final List<AppointmentTypeOption> appointmentTypes;

  const BookingOptions({
    this.services = const [],
    this.departments = const [],
    this.specialists = const [],
    this.appointmentTypes = const [],
  });

  factory BookingOptions.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List<dynamic>? ?? [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    return BookingOptions(
      services: parse('services', ServiceOption.fromJson),
      departments: parse('departments', DepartmentOption.fromJson),
      specialists: parse('specialists', SpecialistOption.fromJson),
      appointmentTypes: parse('appointment_types', AppointmentTypeOption.fromJson),
    );
  }

  @override
  List<Object?> get props => [services, departments, specialists, appointmentTypes];
}

class ServiceOption extends Equatable {
  final int id;
  final String name;
  final int? appointmentTypeId;
  final int? durationMinutes;
  final bool isHome;

  const ServiceOption({
    required this.id,
    required this.name,
    this.appointmentTypeId,
    this.durationMinutes,
    this.isHome = false,
  });

  factory ServiceOption.fromJson(Map<String, dynamic> json) {
    return ServiceOption(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      appointmentTypeId: json['appointment_type_id'] as int?,
      durationMinutes: json['duration_minutes'] as int?,
      isHome: json['is_home'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, name, appointmentTypeId];
}

class DepartmentOption extends Equatable {
  final int id;
  final String name;

  const DepartmentOption({required this.id, required this.name});

  factory DepartmentOption.fromJson(Map<String, dynamic> json) {
    return DepartmentOption(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class SpecialistOption extends Equatable {
  final int id;
  final String name;
  final int? departmentId;

  const SpecialistOption({required this.id, required this.name, this.departmentId});

  factory SpecialistOption.fromJson(Map<String, dynamic> json) {
    return SpecialistOption(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      departmentId: json['department_id'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, name, departmentId];
}

class AppointmentTypeOption extends Equatable {
  final int id;
  final String name;
  final String? key;

  const AppointmentTypeOption({required this.id, required this.name, this.key});

  factory AppointmentTypeOption.fromJson(Map<String, dynamic> json) {
    return AppointmentTypeOption(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      key: json['key'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, key];
}
