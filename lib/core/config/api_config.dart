/// Single source of truth for the DeliverEat API location.
///
/// The exam statement is explicit: if the server restarts and the address
/// changes, updating the app must cost exactly one line. This is that line.
class ApiConfig {
  ApiConfig._();

  /// Base HTTP address of the API (no trailing slash).
  static const String baseUrl = 'https://delivereat.89-167-122-158.sslip.io';

  /// Base WebSocket address, derived from [baseUrl].
  static String get wsBaseUrl =>
      baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

  static const String apiPrefix = '/api';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Turns a relative `/uploads/...` path returned by the API into an
  /// absolute, directly-loadable URL.
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
