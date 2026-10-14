import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const _prefsKey = 'device_id';
  static const _legacyKey = 'device_id';
  static const _channel = MethodChannel('com.scenter.mobile/device');

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    // Migrate from flutter_secure_storage (its storage format has changed
    // across plugin versions, which orphaned previously stored values).
    String? legacy;
    try {
      legacy = await const FlutterSecureStorage().read(key: _legacyKey);
    } catch (_) {
      legacy = null;
    }
    if (legacy != null && legacy.isNotEmpty) {
      await prefs.setString(_prefsKey, legacy);
      return legacy;
    }

    // ANDROID_ID: ثابت لكل (تطبيق + توقيع + مستخدم + جهاز) — يبقى بعد
    // إلغاء التثبيت وإعادة التثبيت، بخلاف المعرّف العشوائي الذي يمحوهالتخزين.
    try {
      final androidId =
          await _channel.invokeMethod<String>('getAndroidId');
      final trimmed = androidId?.trim() ?? '';
      if (trimmed.isNotEmpty && trimmed != 'unknown') {
        final deviceId = 'android-$trimmed';
        await prefs.setString(_prefsKey, deviceId);
        return deviceId;
      }
    } catch (_) {}

    final deviceId =
        'device-${DateTime.now().millisecondsSinceEpoch}-${identityHashCode(this)}';
    await prefs.setString(_prefsKey, deviceId);
    return deviceId;
  }
}
