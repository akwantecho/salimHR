import '../models/models.dart';
import 'api_client.dart';

/// Read-only patient records for specialists.
///
/// Stateless: each screen manages its own loading state (matching the pattern
/// used by the appointment screens), so this service just performs the calls
/// and returns typed models. Errors bubble up as [ApiException] via the
/// client's error interceptor.
class PatientService {
  final ApiClient _client;

  PatientService(this._client);

  /// GET /patients/{id} — profile / demographics.
  Future<Patient> getPatient(int id) async {
    final response = await _client.get<Map<String, dynamic>>('/patients/$id');
    return Patient.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// GET /patients/{id}/appointments — visit history.
  Future<List<PatientVisit>> getAppointments(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/patients/$id/appointments',
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => PatientVisit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /patients/{id}/documents — uploaded document metadata.
  Future<List<PatientDocumentInfo>> getDocuments(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/patients/$id/documents',
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => PatientDocumentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /patients — clinic roster search (reception; `patients.manage`).
  Future<List<Patient>> search({String? term}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/patients',
      queryParameters:
          (term != null && term.isNotEmpty) ? {'search': term} : null,
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Patient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /patients — create a patient (reception; `patients.manage`).
  Future<Patient> create(Map<String, dynamic> body) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/patients',
      data: body,
    );
    return Patient.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// PUT /patients/{id} — update a patient (reception; `patients.manage`).
  Future<Patient> update(int id, Map<String, dynamic> body) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/patients/$id',
      data: body,
    );
    return Patient.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
