/// API Configuration for SalimERP
///
/// Configure the base URL based on your environment.
/// For local development with XAMPP, use your machine's IP address.
class ApiConfig {
  // Change this to your Laravel server URL
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: localhost or 127.0.0.1
  // For physical device use: your machine's IP (e.g., 192.168.1.x)
  static const String baseUrl = 'https://salimerp-gihjjyv1.on-forge.com';

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
