import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Service for authentication operations
class AuthService extends ChangeNotifier {
  final ApiClient _client;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthService(this._client);

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Get CSRF cookie first (for Sanctum)
      await _client.getCsrfCookie();

      final response = await _client.post<Map<String, dynamic>>(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data!;
      final authResponse = AuthResponse.fromJson(data);

      // Save token
      await _client.setToken(authResponse.token);

      // Set current user
      _currentUser = authResponse.user;
      _setLoading(false);
      notifyListeners();

      return true;
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ApiException) {
        _error = apiError.message;
      } else {
        _error = 'Login failed. Please try again.';
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _setLoading(false);
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _client.post('/logout');
    } catch (_) {
      // Ignore errors during logout
    }

    await _client.clearToken();
    await _client.clearRole();
    _currentUser = null;
    _setLoading(false);
    notifyListeners();
  }

  /// Check if user is still authenticated and get current user
  Future<bool> checkAuth() async {
    if (!await _client.hasToken()) {
      return false;
    }

    try {
      final response = await _client.get<Map<String, dynamic>>('/user');
      _currentUser = User.fromJson(response.data!);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (e.error is UnauthorizedException) {
        await _client.clearToken();
        _currentUser = null;
        notifyListeners();
      }
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/user/profile',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      _currentUser = User.fromJson(response.data!['user'] ?? response.data!);
      _setLoading(false);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ApiException) {
        _error = apiError.message;
      } else {
        _error = 'Failed to update profile';
      }
      _setLoading(false);
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _client.put(
        '/user/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );

      _setLoading(false);
      return true;
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ValidationException) {
        _error = apiError.allErrors;
      } else if (apiError is ApiException) {
        _error = apiError.message;
      } else {
        _error = 'Failed to change password';
      }
      _setLoading(false);
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount(String password) async {
    _setLoading(true);
    _error = null;

    try {
      await _client.delete(
        '/user/account',
        data: {'password': password},
      );

      await _client.clearToken();
      await _client.clearRole();
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      final apiError = e.error;
      if (apiError is ValidationException) {
        _error = apiError.allErrors;
      } else if (apiError is ApiException) {
        _error = apiError.message;
      } else {
        _error = 'Failed to delete account';
      }
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
