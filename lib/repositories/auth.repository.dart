import '../services/api.service.dart';
import '../models/user.model.dart';
import '../utils/error_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final _api     = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
        'email':    email,
        'password': password,
      });

      final user = UserModel.fromJson(response.data['data']);
      await _storage.write(key: 'jwt_token', value: user.token);
      return user;

    } catch (e) {
      throw Exception(handleError(e).mensaje);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}