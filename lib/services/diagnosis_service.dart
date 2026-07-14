import '../models/models.dart';
import 'api_client.dart';

/// Diagnosis catalogue search + attaching a diagnosis to an appointment.
///
/// Stateless; errors bubble up as ApiException via the client interceptor.
class DiagnosisService {
  final ApiClient _client;

  DiagnosisService(this._client);

  /// GET /diagnoses?search= — search the code catalogue.
  Future<List<DiagnosisCode>> search(String query) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/diagnoses',
      queryParameters: {if (query.isNotEmpty) 'search': query},
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DiagnosisCode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /appointments/{id}/diagnosis — current diagnosis (may be null).
  Future<DiagnosisCode?> getForAppointment(int appointmentId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/appointments/$appointmentId/diagnosis',
    );
    final data = response.data!['data'];
    return data == null
        ? null
        : DiagnosisCode.fromJson(data as Map<String, dynamic>);
  }

  /// POST /appointments/{id}/diagnosis — attach (or clear with null) a code.
  Future<DiagnosisCode?> setForAppointment({
    required int appointmentId,
    required int? diagnosisCodeId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/appointments/$appointmentId/diagnosis',
      data: {'diagnosis_code_id': diagnosisCodeId},
    );
    final data = response.data!['data'];
    return data == null
        ? null
        : DiagnosisCode.fromJson(data as Map<String, dynamic>);
  }
}
