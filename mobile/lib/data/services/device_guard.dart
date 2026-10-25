import 'package:flutter/services.dart';

/// كشف تشغيل التطبيق على محاكي أندرويد (Waydroid/SDK/Genymotion/qemu...).
/// يستدعي الكود الأصلي في MainActivity — الفحص محلي بلا شبكة.
class DeviceGuard {
  DeviceGuard._();

  static const MethodChannel _channel =
      MethodChannel('com.scenter.mobile/device');

  /// تعيد `true` إذا كان التطبيق يعمل على محاكي.
  /// عند فشل القناة تعيد `false` (لا نُقفل التطبيق على جهاز حقيقي).
  static Future<bool> isEmulator() async {
    try {
      return await _channel.invokeMethod<bool>('isEmulator') ?? false;
    } catch (_) {
      return false;
    }
  }
}
