/// API Configuration for SalimERP
///
/// Configure the base URL based on your environment.
/// For local development with XAMPP, use your machine's IP address.
class ApiConfig {
  // Base URL. Overridable at build/run time without editing code:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  //   flutter build apk --dart-define=API_BASE_URL=https://staging.example.com
  // Falls back to production when the define is absent.
  //   Android emulator: 10.0.2.2 · iOS simulator: localhost/127.0.0.1
  //   Physical device: your machine's LAN IP (e.g. 192.168.1.x)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://salimerp.on-forge.com',
  );

  // API prefix
  static const String apiPrefix = '/api';

  // Full API URL
  static String get apiUrl => '$baseUrl$apiPrefix';

  // Sanctum CSRF cookie endpoint
  static String get csrfCookieUrl => '$baseUrl/sanctum/csrf-cookie';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
