import '../models/models.dart';
import 'api_client.dart';

/// Front-desk appointment operations for the Receptionist shell.
///
/// Stateless (like [PatientService]): each screen owns its loading state and
/// these methods just perform the call and return typed models. Backed by the
/// `/reception/*` API, gated by `appointments.manage`.
class ReceptionService {
  final ApiClient _client;

  ReceptionService(this._client);

  /// GET /reception/appointments — clinic day/range list.
  Future<List<ReceptionAppointment>> getAppointments({
    String? date,
    String? dateFrom,
    String? dateTo,
    String? status,
    String? search,
  }) async {
    final params = <String, dynamic>{
      if (date != null) 'date': date,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await _client.get<Map<String, dynamic>>(
      '/reception/appointments',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ReceptionAppointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /reception/appointments/options — booking form pickers.
  Future<BookingOptions> getBookingOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/reception/appointments/options',
    );
    return BookingOptions.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// GET /reception/appointments/slots — available times for a specialist/day.
  Future<List<AppointmentSlot>> getSlots({
    required int serviceId,
    required int specialistId,
    int? departmentId,
    required String date,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/reception/appointments/slots',
      queryParameters: {
        'service_id': serviceId,
        'specialist_id': specialistId,
        if (departmentId != null) 'department_id': departmentId,
        'date': date,
      },
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => AppointmentSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /reception/appointments — book a single session.
  Future<ReceptionAppointment> bookAppointment(Map<String, dynamic> body) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reception/appointments',
      data: body,
    );
    return ReceptionAppointment.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  /// POST /reception/appointments/{id}/confirm — toggle booked/confirmed.
  Future<ReceptionAppointment> confirm(int id) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reception/appointments/$id/confirm',
    );
    return ReceptionAppointment.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  /// POST /reception/appointments/{id}/attendance — attended/absent/cancelled.
  Future<ReceptionAppointment> setAttendance(
    int id,
    String status, {
    String? reason,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/reception/appointments/$id/attendance',
      data: {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return ReceptionAppointment.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
