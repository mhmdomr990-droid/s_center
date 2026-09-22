import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceService {
  static const _deviceKey = 'device_id';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> getDeviceId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final deviceId = 'device-${DateTime.now().millisecondsSinceEpoch}-${identityHashCode(this)}';
    await _storage.write(key: _deviceKey, value: deviceId);
    return deviceId;
  }
}
