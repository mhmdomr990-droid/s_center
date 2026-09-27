import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _themeKey = 'theme_mode_v2';

  Future<String?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    if (value != null && value.isNotEmpty) return value;

    // Migrate from flutter_secure_storage (its storage format has changed
    // across plugin versions, which orphaned previously stored values).
    String? legacy;
    try {
      legacy = await const FlutterSecureStorage().read(key: key);
    } catch (_) {
      legacy = null;
    }
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(key, legacy);
      return legacy;
    }
    return null;
  }

  Future<void> _write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> saveThemeMode(String mode) async {
    await _write(_themeKey, mode);
  }

  Future<String?> getThemeMode() async {
    return _read(_themeKey);
  }

  Future<void> saveToken(String token) async {
    await _write(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _read(_tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    await _write(_userKey, jsonEncode({
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
    final data = await _read(_userKey);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // الثيم (theme_mode_v2) يبقى عمدًا — تفضيل شخصي لا يُلغى بتسجيل الخروج
    try {
      await const FlutterSecureStorage().deleteAll();
    } catch (_) {}
  }

  Future<bool> hasToken() async {
    final token = await _read(_tokenKey);
    return token != null && token.isNotEmpty;
  }
}
