import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Service for HR operations including dashboard, approvals, and employee management
class HRService extends ChangeNotifier {
  final ApiClient _client;

  HRDashboard? _dashboard;
  List<Approval> _pendingApprovals = [];
  List<LeaveType> _leaveTypes = [];
  Map<String, dynamic> _approvalCounts = {};
  bool _isLoading = false;
  String? _error;

  HRService(this._client);

  // Getters
  HRDashboard? get dashboard => _dashboard;
  List<Approval> get pendingApprovals => _pendingApprovals;
  List<LeaveType> get leaveTypes => _leaveTypes;
  Map<String, dynamic> get approvalCounts => _approvalCounts;
  int get totalPendingApprovals => _approvalCounts['total'] as int? ?? 0;
  int get pendingLeavesCount => _approvalCounts['leaves'] as int? ?? 0;
  int get pendingExcusesCount => _approvalCounts['excuses'] as int? ?? 0;
  int get pendingInventoryCount => _approvalCounts['inventory_requests'] as int? ?? 0;
  int get pendingPayrollCount => _approvalCounts['payroll'] as int? ?? 0;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch HR dashboard data
  Future<void> fetchDashboard() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>('/hr/dashboard');
      _dashboard = HRDashboard.fromJson(response.data!);
      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Fetch all pending approvals
  Future<void> fetchPendingApprovals({String? type}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/approvals',
        queryParameters: type != null ? {'type': type} : null,
      );
      final responseData = response.data!;
      final data = responseData['data'] as Map<String, dynamic>? ?? {};
      _approvalCounts = responseData['counts'] as Map<String, dynamic>? ?? {};

      _pendingApprovals = [];

      // Parse leaves
      final leaves = data['leaves'] as List<dynamic>? ?? [];
      for (final leave in leaves) {
        _pendingApprovals.add(
          Approval.fromJson(leave as Map<String, dynamic>, ApprovalType.leave),
        );
      }

      // Parse medical excuses
      final excuses = data['excuses'] as List<dynamic>? ?? [];
      for (final excuse in excuses) {
        _pendingApprovals.add(
          Approval.fromJson(excuse as Map<String, dynamic>, ApprovalType.medicalExcuse),
        );
      }

      // Parse inventory requests
      final inventory = data['inventory_requests'] as List<dynamic>? ?? [];
      for (final request in inventory) {
        _pendingApprovals.add(
          Approval.fromJson(request as Map<String, dynamic>, ApprovalType.inventory),
        );
      }

      // Parse payroll
      final payroll = data['payroll'] as List<dynamic>? ?? [];
      for (final pay in payroll) {
        _pendingApprovals.add(
          Approval.fromJson(pay as Map<String, dynamic>, ApprovalType.payroll),
        );
      }

      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Approve a leave request
  Future<bool> approveLeave(int leaveId, {String? notes}) async {
    return _processApproval('/approvals/leaves/$leaveId/approve', notes: notes);
  }

  /// Reject a leave request
  Future<bool> rejectLeave(int leaveId, {required String reason}) async {
    return _processApproval('/approvals/leaves/$leaveId/reject', reason: reason);
  }

  /// Approve a medical excuse
  Future<bool> approveExcuse(int excuseId, {String? notes}) async {
    return _processApproval('/approvals/excuses/$excuseId/approve', notes: notes);
  }

  /// Reject a medical excuse
  Future<bool> rejectExcuse(int excuseId, {required String reason}) async {
    return _processApproval('/approvals/excuses/$excuseId/reject', reason: reason);
  }

  /// Approve an inventory request
  Future<bool> approveInventoryRequest(int requestId, {String? notes}) async {
    return _processApproval('/approvals/inventory/$requestId/approve', notes: notes);
  }

  /// Reject an inventory request
  Future<bool> rejectInventoryRequest(int requestId, {required String reason}) async {
    return _processApproval('/approvals/inventory/$requestId/reject', reason: reason);
  }

  /// Approve payroll
  Future<bool> approvePayroll(int payrollId, {String? notes}) async {
    return _processApproval('/approvals/payroll/$payrollId/approve', notes: notes);
  }

  /// Reject payroll
  Future<bool> rejectPayroll(int payrollId, {required String reason}) async {
    return _processApproval('/approvals/payroll/$payrollId/reject', reason: reason);
  }

  /// Generic approval processing
  Future<bool> _processApproval(String endpoint, {String? notes, String? reason}) async {
    _setLoading(true);
    _error = null;

    try {
      await _client.post(
        endpoint,
        data: {
          if (notes != null) 'notes': notes,
          if (reason != null) 'reason': reason,
        },
      );

      // Refresh approvals list
      await fetchPendingApprovals();
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Fetch HR reports
  Future<Map<String, dynamic>> fetchReport({
    required String type,
    String? startDate,
    String? endDate,
    int? departmentId,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/hr/reports',
        queryParameters: {
          'type': type,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (departmentId != null) 'department_id': departmentId,
        },
      );
      return response.data ?? {};
    } on DioException catch (e) {
      _handleError(e);
      return {};
    }
  }

  /// Fetch leave types (admin scope — uses /hr/leave-types).
  Future<void> fetchLeaveTypes() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/hr/leave-types');
      final data = response.data!['data'] as List<dynamic>? ?? [];
      _leaveTypes = data
          .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Fetch leave types accessible to the authenticated employee (no admin
  /// permission required). Used by the specialist leave request form.
  Future<List<LeaveType>> fetchMyLeaveTypes() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/employee/leave-types');
      final data = response.data!['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  /// Fetch employee bonuses and deductions (admin)
  Future<List<EmployeeBonus>> fetchBonusesDeductions({
    int? employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/hr/bonuses',
        queryParameters: {
          if (employeeId != null) 'employee_id': employeeId,
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );

      final wrapper = response.data!['data'];
      final List<dynamic> items;
      if (wrapper is Map<String, dynamic>) {
        items = wrapper['data'] as List<dynamic>? ?? [];
      } else if (wrapper is List) {
        items = wrapper;
      } else {
        items = [];
      }
      return items
          .map((e) => EmployeeBonus.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  /// Add bonus or deduction (admin)
  Future<bool> addBonusDeduction({
    required int employeeId,
    required String type,
    required double amount,
    String? reason,
    required int month,
    required int year,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _client.post(
        '/hr/bonuses',
        data: {
          'employee_id': employeeId,
          'bonus_type': type,
          'amount': amount,
          'reason': reason,
          'period_month': month,
          'period_year': year,
        },
      );

      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ==================== EMPLOYEE SELF-SERVICE ====================

  /// Fetch the authenticated employee's bonuses (self-service)
  Future<Map<String, dynamic>> fetchMyBonuses({int? month, int? year}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/employee/bonuses',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return response.data ?? {};
    } on DioException catch (e) {
      _handleError(e);
      return {};
    }
  }

  /// Fetch the authenticated employee's notes (self-service)
  Future<List<EmployeeNote>> fetchMyNotes({String direction = 'all'}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/employee/notes',
        queryParameters: {'direction': direction},
      );
      final data = response.data!['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => EmployeeNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  /// Send a note from employee to admin (self-service)
  Future<bool> sendMyNote(String note) async {
    _setLoading(true);
    _error = null;

    try {
      await _client.post(
        '/employee/notes',
        data: {'note': note},
      );
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Summary of the authenticated employee's own leaves.
  /// Returns a map: `{pending: int, approved: int, rejected: int,
  /// approved_this_month: int}`. Empty map on failure (error set on service).
  Future<Map<String, int>> fetchMyLeavesSummary() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/employee/leaves');
      final summary = response.data?['summary'] as Map<String, dynamic>? ?? {};
      return summary.map((k, v) => MapEntry(k, (v as num).toInt()));
    } on DioException catch (e) {
      _handleError(e);
      return {};
    }
  }

  /// Submit a leave request (employee self-service).
  /// Returns true on success.
  Future<bool> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _client.post(
        '/employee/leaves',
        data: {
          'leave_type_id': leaveTypeId,
          'start_date': startDate,
          'end_date': endDate,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Submit a structured employee request (patient_transfer or loan).
  /// Backed by EmployeeNote on the server side with a typed header.
  Future<bool> submitEmployeeRequest({
    required String type,
    String? subject,
    required String details,
    double? amount,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _client.post(
        '/employee/requests',
        data: {
          'type': type,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          'details': details,
          if (amount != null) 'amount': amount,
        },
      );
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Fetch the authenticated employee's monthly attendance log.
  Future<Map<String, dynamic>> fetchMyAttendance({int? month, int? year}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/employee/attendance',
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      return response.data ?? {};
    } on DioException catch (e) {
      _handleError(e);
      return {};
    }
  }

  /// Today's attendance row for the authenticated employee.
  /// Returns null on failure (with [error] set on this service).
  Future<AttendanceToday?> fetchTodayAttendance() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/employee/attendance/today');
      final raw = response.data?['data'] as Map<String, dynamic>?;
      if (raw == null) return null;
      return AttendanceToday.fromJson(raw);
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Record a check-in for "now". Returns the updated AttendanceToday on
  /// success, or null on failure ([error] is set).
  Future<AttendanceToday?> checkIn({String? location, String? notes}) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/employee/attendance/check-in',
        data: {
          if (location != null && location.isNotEmpty) 'location': location,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      _setLoading(false);
      final raw = response.data?['data'] as Map<String, dynamic>?;
      if (raw == null) return null;
      return AttendanceToday(
        date: DateTime.parse(raw['date'] as String),
        checkInAt: raw['check_in_at'] != null
            ? DateTime.tryParse(raw['check_in_at'] as String)
            : null,
        checkOutAt: raw['check_out_at'] != null
            ? DateTime.tryParse(raw['check_out_at'] as String)
            : null,
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Record a check-out for "now". Same return contract as [checkIn].
  Future<AttendanceToday?> checkOut({String? location, String? notes}) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/employee/attendance/check-out',
        data: {
          if (location != null && location.isNotEmpty) 'location': location,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      _setLoading(false);
      final raw = response.data?['data'] as Map<String, dynamic>?;
      if (raw == null) return null;
      return AttendanceToday(
        date: DateTime.parse(raw['date'] as String),
        checkInAt: raw['check_in_at'] != null
            ? DateTime.tryParse(raw['check_in_at'] as String)
            : null,
        checkOutAt: raw['check_out_at'] != null
            ? DateTime.tryParse(raw['check_out_at'] as String)
            : null,
      );
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Fetch the authenticated specialist's appointments
  Future<Map<String, dynamic>> fetchMyAppointments({
    String? date,
    String? startDate,
    String? endDate,
    String? scope,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/appointments/my',
        queryParameters: {
          if (date != null) 'date': date,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (scope != null) 'scope': scope,
        },
      );
      return response.data ?? {};
    } on DioException catch (e) {
      _handleError(e);
      return {};
    }
  }

  /// Fetch a single appointment's details for the specialist.
  Future<Map<String, dynamic>?> fetchAppointment(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/appointments/$id');
      return response.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Finalize an appointment from the specialist's mobile app.
  ///
  /// [action] must be 'complete' or 'no_show'. [notes] is required by the
  /// backend (min 3 chars) — the UI must enforce non-empty before calling.
  /// Returns the updated appointment payload, or null on failure (the error
  /// is set on the service and notifies listeners).
  Future<Map<String, dynamic>?> updateAppointmentStatus({
    required int appointmentId,
    required String action,
    required String notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/appointments/$appointmentId/status',
        data: {'action': action, 'notes': notes},
      );
      _setLoading(false);
      return response.data?['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleError(DioException e) {
    final apiError = e.error;
    if (apiError is ApiException) {
      _error = apiError.message;
    } else {
      _error = 'An error occurred';
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
