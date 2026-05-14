class AppConfig {
  static const String baseUrl   = 'https://riego-backend-production.up.railway.app';
  static const String apiUrl    = '$baseUrl/api';
  static const String socketUrl = baseUrl;

  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}