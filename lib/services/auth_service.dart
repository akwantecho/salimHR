import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/user_document.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Service for authentication operations
class AuthService extends ChangeNotifier {
  final ApiClient _client;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  Uint8List? _avatarBytes;

  AuthService(this._client);

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  /// Locally selected avatar image (not yet uploaded). Displayed immediately in
  /// the profile; when a backend is wired up this would be sent and cleared.
  Uint8List? get avatarBytes => _avatarBytes;

  void setAvatarBytes(Uint8List bytes) {
    _avatarBytes = bytes;
    notifyListeners();
  }

  /// Fetch the authenticated user's documents.
  Future<List<UserDocument>> fetchDocuments() async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/user/documents');
      final data = res.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => UserDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final apiError = e.error;
      _error = apiError is ApiException ? apiError.message : 'Failed to load documents';
      return [];
    }
  }

  /// Upload (or replace) a document of [type]. Returns the stored document.
  Future<UserDocument?> uploadDocument({
    required String type,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'type': type,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _client.post<Map<String, dynamic>>(
        '/user/documents',
        data: form,
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      return data != null ? UserDocument.fromJson(data) : null;
    } on DioException catch (e) {
      final apiError = e.error;
      _error = apiError is ApiException ? apiError.message : 'Upload failed';
      return null;
    }
  }

  /// Delete a document by id.
  Future<bool> deleteDocument(int id) async {
    try {
      await _client.delete('/user/documents/$id');
      return true;
    } on DioException catch (e) {
      final apiError = e.error;
      _error = apiError is ApiException ? apiError.message : 'Delete failed';
      return false;
    }
  }

  /// Uploads the selected avatar image to the server (`POST /user/avatar`).
  /// Returns the stored avatar URL on success, or null on failure.
  Future<String?> uploadAvatar(Uint8List bytes, {String filename = 'avatar.jpg'}) async {
    try {
      final form = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _client.post<Map<String, dynamic>>(
        '/user/avatar',
        data: form,
      );
      return response.data?['data']?['avatar_url'] as String?;
    } on DioException catch (e) {
      final apiError = e.error;
      _error = apiError is ApiException ? apiError.message : 'Avatar upload failed';
      return null;
    }
  }

  /// Sets a local demo user without any network call. Used by demo mode so
  /// screens that read [currentUser] (e.g. the salary screen's employeeId)
  /// have data to work with. No effect on real logins.
  void setDemoUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Get CSRF cookie first (for Sanctum)
      await _client.getCsrfCookie();

      final response = await _client.post<Map<String, dynamic>>(
        '/login',
        data: {'email': email, 'password': password},
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
  Future<bool> updateProfile({String? name, String? phone}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/user/profile',
        data: {'name': ?name, 'phone': ?phone},
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
      await _client.delete('/user/account', data: {'password': password});

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
