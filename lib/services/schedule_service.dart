import '../models/models.dart';
import 'api_client.dart';

/// The specialist's own weekly schedule + daily open slots (read-only).
class ScheduleService {
  final ApiClient _client;

  ScheduleService(this._client);

  /// GET /me/schedule/weekly
  Future<List<ScheduleDay>> getWeekly() async {
    final response =
        await _client.get<Map<String, dynamic>>('/me/schedule/weekly');
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ScheduleDay.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /me/slots?date=YYYY-MM-DD
  Future<DaySlots> getSlots(String date) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/me/slots',
      queryParameters: {'date': date},
    );
    final data = response.data!;
    final slots = (data['data'] as List<dynamic>? ?? [])
        .map((e) => DaySlot.fromJson(e as Map<String, dynamic>))
        .toList();
    return DaySlots(slots: slots, reason: data['reason'] as String?);
  }
}
