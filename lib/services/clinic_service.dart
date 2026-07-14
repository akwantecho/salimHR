import '../models/models.dart';
import 'api_client.dart';

/// Clinic overview + drill-downs for the manager. Stateless; errors bubble up
/// as ApiException via the client interceptor.
class ClinicService {
  final ApiClient _client;

  ClinicService(this._client);

  /// GET /clinic/overview
  Future<ClinicOverview> getOverview() async {
    final response =
        await _client.get<Map<String, dynamic>>('/clinic/overview');
    return ClinicOverview.fromJson(
        response.data!['data'] as Map<String, dynamic>);
  }

  /// GET /clinic/appointments?date=
  Future<List<ClinicAppointment>> getAppointments({String? date}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/clinic/appointments',
      queryParameters: {if (date != null) 'date': date},
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ClinicAppointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /clinic/revenue?from=&to= (finance.view only)
  Future<RevenueReport> getRevenue({String? from, String? to}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/clinic/revenue',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return RevenueReport.fromJson(
        response.data!['data'] as Map<String, dynamic>);
  }

  /// GET /clinic/patients?search=
  Future<List<ClinicPatient>> getPatients({String? search}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/clinic/patients',
      queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ClinicPatient.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
