import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// كاش "آخر جلسة فقط" — كل مفتاح يُستبدل في مكانه عند كل نجاح،
/// ولا يُبنى فوقه تاريخ ولا نسخ متعددة.
/// المعزل بالحساب: كل مستخدم بمفتاحيه الخاصين، وبلا نطاق نشط
/// (لا تسجيل دخول) لا قراءة ولا كتابة إطلاقاً.
class OfflineCache {
  OfflineCache._();

  static const _catalogLegacyKey = 'offline_catalog_v1';
  static const _lecturesLegacyPrefix = 'offline_lectures_v1_';

  static int? scope;

  static String? get _catalogKey =>
      scope == null ? null : 'offline_catalog_v1__u$scope';

  static String? _lecturesKey(int courseId) =>
      scope == null ? null : 'offline_lectures_v1__u${scope}_$courseId';

  /// ضبط نطاق المستخدم — يُستدعى من AuthController عند الدخول/الخروج.
  static Future<void> setScope(int? userId) async {
    scope = userId;
  }

  /// ترحيل المفتاح العالمي القديم (إن وُجد) إلى مفتاح النطاق الحالي
  /// وحذفه — مرة واحدة لأول مستخدم يفتح الكاش بعد التحديث.
  static Future<String?> _adoptLegacy(
      SharedPreferences prefs, String scopedKey, String legacyKey) async {
    if (prefs.containsKey(scopedKey)) return prefs.getString(scopedKey);
    final legacy = prefs.getString(legacyKey);
    if (legacy == null || legacy.isEmpty) return null;
    try {
      await prefs.setString(scopedKey, legacy);
      await prefs.remove(legacyKey);
    } catch (e) {
      debugPrint('OFFLINE_CACHE_MIGRATE $e');
      return legacy;
    }
    return legacy;
  }

  static Future<void> saveCatalog(
      List<dynamic> specializations, List<dynamic> courses) async {
    final key = _catalogKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'specializations': specializations,
        'courses': courses,
      }));
    } catch (e) {
      debugPrint('OFFLINE_CACHE_SAVE_CATALOG $e');
    }
  }

  static Future<Map<String, dynamic>?> loadCatalog() async {
    final key = _catalogKey;
    if (key == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = await _adoptLegacy(prefs, key, _catalogLegacyKey);
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      debugPrint('OFFLINE_CACHE_LOAD_CATALOG $e');
      return null;
    }
  }

  static Future<void> saveCourseDetail(int courseId,
      Map<String, dynamic> course, List<dynamic> lectures) async {
    final key = _lecturesKey(courseId);
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'course': course,
        'lectures': lectures,
      }));
    } catch (e) {
      debugPrint('OFFLINE_CACHE_SAVE_COURSE $e');
    }
  }

  static Future<Map<String, dynamic>?> loadCourseDetail(int courseId) async {
    final key = _lecturesKey(courseId);
    if (key == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      // المفتاح القديم لاحقته أرقام فقط (offline_lectures_v1_<id>) بينما
      // المفتاح المنطَّق يحوي __u — لا تصادم بينهما.
      final raw = await _adoptLegacy(
          prefs, key, '$_lecturesLegacyPrefix$courseId');
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      debugPrint('OFFLINE_CACHE_LOAD_COURSE $e');
      return null;
    }
  }
}
