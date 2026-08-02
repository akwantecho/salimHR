import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Service for payroll operations
class PayrollService extends ChangeNotifier {
  final ApiClient _client;

  List<PayrollRun> _payrollRuns = [];
  PayrollRun? _currentPayroll;
  List<EmployeeBonus> _currentBonuses = [];
  bool _isLoading = false;
  String? _error;

  PayrollService(this._client);

  // Getters
  List<PayrollRun> get payrollRuns => _payrollRuns;
  PayrollRun? get currentPayroll => _currentPayroll;
  List<EmployeeBonus> get currentBonuses => _currentBonuses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all payroll runs
  Future<void> fetchPayrollRuns({int? year}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/payroll',
        queryParameters: {
          'year': ?year,
        },
      );

      final data = response.data!['data'] as List<dynamic>? ?? [];
      _payrollRuns = data
          .map((e) => PayrollRun.fromJson(e as Map<String, dynamic>))
          .toList();

      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Fetch a single payroll run with items
  Future<void> fetchPayroll(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.get<Map<String, dynamic>>('/payroll/$id');
      _currentPayroll = PayrollRun.fromJson(response.data!);
      _setLoading(false);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Create a new payroll run
  Future<PayrollRun?> createPayroll({
    required int month,
    required int year,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/payroll',
        data: {
          'month': month,
          'year': year,
        },
      );

      final payroll = PayrollRun.fromJson(response.data!);
      _payrollRuns.insert(0, payroll);
      _currentPayroll = payroll;
      _setLoading(false);
      notifyListeners();
      return payroll;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// Submit payroll for approval
  Future<bool> submitForApproval(int payrollId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/payroll/$payrollId/submit',
      );

      _currentPayroll = PayrollRun.fromJson(response.data!);
      _updatePayrollInList(_currentPayroll!);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Approve payroll (for managers)
  Future<bool> approvePayroll(int payrollId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/payroll/$payrollId/approve',
      );

      _currentPayroll = PayrollRun.fromJson(response.data!);
      _updatePayrollInList(_currentPayroll!);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Lock payroll (finalize)
  Future<bool> lockPayroll(int payrollId) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/payroll/$payrollId/lock',
      );

      _currentPayroll = PayrollRun.fromJson(response.data!);
      _updatePayrollInList(_currentPayroll!);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Get employee's salary for a specific period
  Future<PayrollItem?> getEmployeeSalary({
    required int employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/payroll/employee/$employeeId',
        queryParameters: {
          'month': ?month,
          'year': ?year,
        },
      );

      if (response.data != null && response.data!.isNotEmpty) {
        return PayrollItem.fromJson(response.data!);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Fetch employee's bonuses for a period
  Future<void> fetchEmployeeBonuses({
    required int employeeId,
    int? month,
    int? year,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/hr/bonuses',
        queryParameters: {
          'employee_id': employeeId,
          'month': ?month,
          'year': ?year,
        },
      );

      final data = response.data!['data'] as List<dynamic>? ?? [];
      _currentBonuses = data
          .map((e) => EmployeeBonus.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Get payment history for an employee
  Future<List<PayrollItem>> getPaymentHistory(int employeeId, {int limit = 6}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/payroll/employee/$employeeId/history',
        queryParameters: {'limit': limit},
      );

      final data = response.data!['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => PayrollItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  void _updatePayrollInList(PayrollRun payroll) {
    final index = _payrollRuns.indexWhere((p) => p.id == payroll.id);
    if (index != -1) {
      _payrollRuns[index] = payroll;
    }
    notifyListeners();
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
