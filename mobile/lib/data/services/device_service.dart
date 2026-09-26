import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const _prefsKey = 'device_id';
  static const _legacyKey = 'device_id';

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

    final deviceId =
        'device-${DateTime.now().millisecondsSinceEpoch}-${identityHashCode(this)}';
    await prefs.setString(_prefsKey, deviceId);
    return deviceId;
  }
}
