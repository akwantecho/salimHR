import '../models/models.dart';
import 'api_client.dart';

/// Treatment plan reads + session reschedule/cancel for specialists.
///
/// Stateless (like [PatientService]); the screen owns its loading state.
/// Errors bubble up as ApiException via the client's error interceptor.
class TreatmentPlanService {
  final ApiClient _client;

  TreatmentPlanService(this._client);

  /// GET /treatment-plans/{id} — plan detail with sessions.
  Future<TreatmentPlanDetail> getPlan(int id) async {
    final response =
        await _client.get<Map<String, dynamic>>('/treatment-plans/$id');
    return TreatmentPlanDetail.fromJson(
        response.data!['data'] as Map<String, dynamic>);
  }

  /// POST /treatment-plan-sessions/{id}/reschedule
  Future<TreatmentSession> rescheduleSession({
    required int sessionId,
    required String plannedDate,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/treatment-plan-sessions/$sessionId/reschedule',
      data: {'planned_date': plannedDate},
    );
    return TreatmentSession.fromJson(
        response.data!['data'] as Map<String, dynamic>);
  }

  /// POST /treatment-plan-sessions/{id}/cancel
  Future<TreatmentSession> cancelSession(int sessionId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/treatment-plan-sessions/$sessionId/cancel',
    );
    return TreatmentSession.fromJson(
        response.data!['data'] as Map<String, dynamic>);
  }
}
