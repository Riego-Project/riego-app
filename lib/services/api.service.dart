import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.apiUrl,
      connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
      contentType:    'application/json',
    ));

    // Interceptor: agrega el token JWT a cada request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path)                          => _dio.get(path);
  Future<Response> post(String path, dynamic data)           => _dio.post(path, data: data);
  Future<Response> put(String path, dynamic data)            => _dio.put(path, data: data);
  Future<Response> delete(String path)                       => _dio.delete(path);
}