import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';
import 'api_exceptions.dart';
import 'demo_data.dart';

/// Main API client using Dio for HTTP requests.
/// Handles authentication tokens, error handling, and request/response logging.
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: ApiConfig.apiUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    headers: ApiConfig.defaultHeaders,
  );

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      // Inert unless ApiConfig.demoMode is on; must run first so it can
      // short-circuit requests with mock data before they hit the network.
      DemoInterceptor(),
      _AuthInterceptor(this),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  // Token management. The token is cached in memory and reads are time-boxed so
  // a slow/hanging secure-storage call (seen on some Android devices) can never
  // stall an outgoing request — which otherwise hangs login forever.
  String? _cachedToken;
  bool _tokenLoaded = false;

  Future<String?> getToken() async {
    try {
      _cachedToken =
          await _storage.read(key: _tokenKey).timeout(const Duration(seconds: 3));
      _tokenLoaded = true;
    } catch (_) {
      // Keep the last known value on timeout/error.
    }
    return _cachedToken;
  }

  /// Cached token for synchronous access inside interceptors (never blocks).
  String? get cachedToken => _cachedToken;
  bool get tokenLoaded => _tokenLoaded;

  Future<void> setToken(String token) async {
    _cachedToken = token;
    _tokenLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async => (await getToken()) != null;

  // Role management (for session persistence)
  Future<void> setRole(String role) => _storage.write(key: _roleKey, value: role);

  Future<String?> getRole() => _storage.read(key: _roleKey);

  Future<void> clearRole() => _storage.delete(key: _roleKey);

  // HTTP Methods
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Get CSRF cookie for Sanctum authentication
  Future<void> getCsrfCookie() async {
    await Dio().get(ApiConfig.csrfCookieUrl);
  }
}

/// Interceptor to add auth token to requests
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Use the in-memory token when already loaded (never blocks); only read
    // secure storage the first time, and even then it's time-boxed in getToken.
    String? token = _client.cachedToken;
    if (token == null && !_client.tokenLoaded) {
      token = await _client.getToken();
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Interceptor for logging requests/responses in debug mode
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('→ ${options.method} ${options.uri}');
      if (options.data != null) {
        debugPrint('  Body: ${options.data}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✕ ${err.response?.statusCode} ${err.requestOptions.uri}');
      debugPrint('  Error: ${err.message}');
    }
    handler.next(err);
  }
}

/// Interceptor to transform Dio errors into API exceptions
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = ApiException.fromDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        response: err.response,
        type: err.type,
      ),
    );
  }
}
