import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthProvider {
  final ApiClient _api;

  AuthProvider(this._api);

  Future<Response> login({required String username, required String password, String? deviceId}) {
    return _api.post('/auth/login', data: {
      'username': username,
      'password': password,
      if (deviceId != null) 'device_id': deviceId,
    });
  }

  Future<Response> register({
    required String username,
    required String fullName,
    required String password,
    required String deviceId,
  }) {
    return _api.post('/auth/register', data: {
      'username': username,
      'full_name': fullName,
      'password': password,
      'device_id': deviceId,
    });
  }

  Future<Response> getMe() {
    return _api.get('/auth/me');
  }

  Future<Response> changePassword({required String oldPassword, required String newPassword}) {
    return _api.post('/auth/change-password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<Response> logoutAll() {
    return _api.post('/auth/logout-all');
  }
}
