import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// كاش "آخر جلسة فقط" — كل مفتاح يُستبدل في مكانه عند كل نجاح،
/// ولا يُبنى فوقه تاريخ ولا نسخ متعددة.
class OfflineCache {
  OfflineCache._();

  static const _catalogKey = 'offline_catalog_v1';
  static const _lecturesKeyPrefix = 'offline_lectures_v1_';

  static Future<void> saveCatalog(
      List<dynamic> specializations, List<dynamic> courses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_catalogKey, jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'specializations': specializations,
        'courses': courses,
      }));
    } catch (e) {
      debugPrint('OFFLINE_CACHE_SAVE_CATALOG $e');
    }
  }

  static Future<Map<String, dynamic>?> loadCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_catalogKey);
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      debugPrint('OFFLINE_CACHE_LOAD_CATALOG $e');
      return null;
    }
  }

  static Future<void> saveCourseDetail(int courseId,
      Map<String, dynamic> course, List<dynamic> lectures) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_lecturesKeyPrefix$courseId', jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'course': course,
        'lectures': lectures,
      }));
    } catch (e) {
      debugPrint('OFFLINE_CACHE_SAVE_COURSE $e');
    }
  }

  static Future<Map<String, dynamic>?> loadCourseDetail(int courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_lecturesKeyPrefix$courseId');
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (e) {
      debugPrint('OFFLINE_CACHE_LOAD_COURSE $e');
      return null;
    }
  }
}
