/// API Configuration for SalimERP
///
/// Configure the base URL based on your environment.
/// For local development with XAMPP, use your machine's IP address.
class ApiConfig {
  // Change this to your Laravel server URL
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: localhost or 127.0.0.1
  // For physical device use: your machine's IP (e.g., 192.168.1.x)
  static const String baseUrl = 'https://salimerp.on-forge.com';

  /// When `true`, all API calls are served from local mock data instead of the
  /// network (see [DemoInterceptor]). Off by default — enabled only by the
  /// demo-login buttons for previewing the UI without a backend server.
  static bool demoMode = false;

  // API prefix
  static const String apiPrefix = '/api';

  // Full API URL
  static String get apiUrl => '$baseUrl$apiPrefix';

  // Sanctum CSRF cookie endpoint
  static String get csrfCookieUrl => '$baseUrl/sanctum/csrf-cookie';

  // Timeouts — kept modest so a stalled request surfaces an error quickly
  // instead of appearing to load forever.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
