import 'package:flutter/foundation.dart';
import 'package:screen_security/screen_security.dart';

class ScreenGuard {
  ScreenGuard._();

  static final ScreenGuard instance = ScreenGuard._();

  final ScreenSecurity _plugin = ScreenSecurity();
  bool _enabled = false;

  Future<void> protect() async {
    if (kIsWeb) return;
    try {
      await _plugin.enable();
      _enabled = true;
    } catch (_) {}
  }

  Future<void> unprotect() async {
    if (kIsWeb) return;
    if (!_enabled) return;
    try {
      await _plugin.disable();
    } catch (_) {}
    _enabled = false;
  }
}
