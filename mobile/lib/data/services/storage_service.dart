import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _userKey, value: jsonEncode({
      'id': user.id,
      'username': user.username,
      'full_name': user.fullName,
      'role': user.role,
      'is_active': user.isActive,
      'is_test': user.isTest,
      'balance': user.balance,
    }));
  }

  Future<UserModel?> getUser() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
}
