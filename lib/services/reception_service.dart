import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/reception.dart';
import 'api_client.dart';

/// Service for the Reception (front desk) role — dashboard, clinic appointments,
/// patient search/registration, and booking. Backed by `/api/reception/*`.
class ReceptionService extends ChangeNotifier {
  final ApiClient _client;

  bool _isLoading = false;
  String? _error;

  ReceptionService(this._client);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Front-desk dashboard: `{ stats: {...}, appointments: [...] }`.
  Future<Map<String, dynamic>> fetchDashboard() async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/dashboard',
      );
      return res.data?['data'] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      _error = e.message;
      return {};
    }
  }

  Future<List<ReceptionAppointment>> fetchAppointments({String? date}) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/appointments',
        queryParameters: {if (date != null) 'date': date},
      );
      final data = res.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => ReceptionAppointment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = e.message;
      return [];
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/patients',
        queryParameters: {if (query.isNotEmpty) 'search': query},
      );
      final data = res.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = e.message;
      return [];
    }
  }

  /// Full patient file for reception: profile + appointments + sessions summary.
  /// Backed by `GET /api/reception/patients/{id}`.
  Future<Map<String, dynamic>?> fetchPatientDetail(int id) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/patients/$id',
      );
      return res.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      _error = e.message;
      return null;
    }
  }

  Future<Patient?> createPatient({
    required String name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? nationality,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/reception/patients',
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null && dateOfBirth.isNotEmpty)
            'date_of_birth': dateOfBirth,
          if (nationality != null && nationality.isNotEmpty)
            'nationality': nationality,
        },
      );
      _setLoading(false);
      final data = res.data?['data'] as Map<String, dynamic>?;
      return data != null ? Patient.fromJson(data) : null;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to create patient';
      _setLoading(false);
      return null;
    }
  }

  Future<List<NamedRef>> fetchSpecialists() async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/specialists',
      );
      final data = res.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => NamedRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = e.message;
      return [];
    }
  }

  /// Active staff who can receive notifications (doctors, admins, specialists).
  Future<List<NamedRef>> fetchRecipients() async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/recipients',
      );
      final data = res.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => NamedRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = e.message;
      return [];
    }
  }

  Future<List<ServiceOption>> fetchServices() async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        '/reception/services',
      );
      final data = res.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => ServiceOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _error = e.message;
      return [];
    }
  }

  Future<ReceptionAppointment?> book({
    required int patientId,
    required int specialistId,
    required int serviceId,
    required String date,
    required String startTime,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/reception/appointments',
        data: {
          'patient_id': patientId,
          'specialist_employee_id': specialistId,
          'service_id': serviceId,
          'appointment_date': date,
          'start_time': startTime,
        },
      );
      _setLoading(false);
      final data = res.data?['data'] as Map<String, dynamic>?;
      return data != null ? ReceptionAppointment.fromJson(data) : null;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to book appointment';
      _setLoading(false);
      return null;
    }
  }

  /// Sends a notification to one specialist (by id) or all when [specialistId]
  /// is null. Returns how many were sent, or null on failure.
  /// Uploads an image to attach to a notification; returns its public URL.
  Future<String?> uploadNotificationImage(
    Uint8List bytes, {
    String filename = 'notice.jpg',
  }) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _client.post<Map<String, dynamic>>(
        '/reception/notification-image',
        data: form,
      );
      return res.data?['data']?['image_url'] as String?;
    } on DioException catch (e) {
      _error = e.message;
      return null;
    }
  }

  Future<int?> sendNotification({
    required String title,
    required String message,
    int? specialistId,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _client.post<Map<String, dynamic>>(
        '/reception/notifications',
        data: {
          'title': title,
          'message': message,
          if (specialistId != null) 'specialist_id': specialistId,
          if (imageUrl != null) 'image_url': imageUrl,
        },
      );
      _setLoading(false);
      return (res.data?['data']?['sent'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      _error = e.message ?? 'Failed to send notification';
      _setLoading(false);
      return null;
    }
  }

  Future<bool> cancel(int appointmentId, {String? reason}) async {
    try {
      await _client.post(
        '/reception/appointments/$appointmentId/cancel',
        data: {if (reason != null) 'reason': reason},
      );
      return true;
    } on DioException catch (e) {
      _error = e.message;
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
