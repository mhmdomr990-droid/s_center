import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import 'app_colors.dart';

class ThemeController extends GetxController {
  ThemeController(this._storage);

  final StorageService _storage;

  final themeMode = ThemeMode.light.obs;

  bool get isDark => themeMode.value == ThemeMode.dark;

  Future<void> loadSaved() async {
    final saved = await _storage.getThemeMode();
    final dark = saved != 'light';
    AppColors.setDarkMode(dark);
    themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
    _applySystemChrome(dark);
  }

  Future<void> toggle(bool dark) async {
    AppColors.setDarkMode(dark);
    themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
    Get.changeThemeMode(themeMode.value);
    _applySystemChrome(dark);
    await _storage.saveThemeMode(dark ? 'dark' : 'light');
  }

  void _applySystemChrome(bool dark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: dark ? AppColors.background : AppColors.primary,
      statusBarIconBrightness: Brightness.light,
    ));
  }
}
