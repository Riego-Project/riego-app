class AppConfig {
  // static const String baseUrl     = 'http://localhost:3000';
  static const String baseUrl     = 'https://vascular-habitat-correct.ngrok-free.dev';
  static const String apiUrl      = '$baseUrl/api';
  static const String socketUrl   = baseUrl;

  // Timeouts
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}