import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/api_client.dart';
import '../../data/providers/api_exception.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/device_service.dart';
import '../../data/services/download_manager.dart';
import '../../data/services/offline_cache.dart';
import '../../data/models/user_model.dart';
import '../../app/routes/app_routes.dart';
import '../home_shell.dart';
import '../admin/admin_shell.dart';

class AuthController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final StorageService _storage = Get.find<StorageService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  late final AuthProvider _authProvider;

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final loginRole = 'STUDENT'.obs;
  final user = Rxn<UserModel>();
  // آخر رسالة خطأ دخول — تبقى معروضة في الشاشة حتى بعد اختفاء النافذة
  final lastError = ''.obs;
  bool _authChecked = false;

  final loginUsernameCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();

  /// ربط نطاق البيانات المحلية (تنزيلات + كاش دورات) بالحساب الحالي —
  /// استدعاء عند كل نجاح دخول/تسجيل/استعادة جلسة.
  void _syncScope(UserModel u) {
    unawaited(Get.find<DownloadManager>().scopeToUser(u.id));
    unawaited(OfflineCache.setScope(u.id));
  }

  /// فك النطاق عند الخروج أو انتهاء الجلسة — تُفرَّغ الذاكرة ويُمنع الوصول.
  void _clearScope() {
    unawaited(Get.find<DownloadManager>().clearScope());
    unawaited(OfflineCache.setScope(null));
  }

  final registerUsernameCtrl = TextEditingController();
  final registerFullNameCtrl = TextEditingController();
  final registerPasswordCtrl = TextEditingController();
  final registerConfirmCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _authProvider = AuthProvider(_apiClient);
  }

  @override
  void onClose() {
    loginUsernameCtrl.dispose();
    loginPasswordCtrl.dispose();
    registerUsernameCtrl.dispose();
    registerFullNameCtrl.dispose();
    registerPasswordCtrl.dispose();
    registerConfirmCtrl.dispose();
    super.onClose();
  }

  Future<void> login() async {
    if (loginUsernameCtrl.text.isEmpty || loginPasswordCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'أدخل اسم المستخدم وكلمة المرور', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    lastError.value = '';
    try {
      final deviceId = await _deviceService.getDeviceId();
      final response = await _authProvider.login(
        username: loginUsernameCtrl.text.trim(),
        password: loginPasswordCtrl.text,
        deviceId: deviceId,
      );

      final data = response.data['data'];
      final token = data['token'] as String;
      final userData = UserModel.fromJson(data['user']);

      if (loginRole.value != userData.role) {
        // نوع الحساب لا يطابق التبويب المختار — نعرض رسالة بيانات الدخول
        // القياسية نفسها (بلا كشف نوع الحساب) ونمنع الدخول قبل حفظ التوكن
        Get.snackbar(
          'خطأ',
          'اسم المستخدم أو كلمة المرور غير صحيحة',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _storage.saveToken(token);
      await _storage.saveUser(userData);
      user.value = userData;
      _syncScope(userData);

      if (userData.isAdmin) {
        Get.offAll(() => const AdminShell());
      } else if (userData.isTeacher) {
        Get.offAll(() => const TeacherShell());
      } else {
        Get.offAll(() => const StudentShell());
      }
    } catch (e) {
      // الشريط الأحمر أسفل حقل العنوان يعرض الخطأ — بلا نافذة منبثقة
      final status = e is DioException ? e.response?.statusCode : null;
      if (status == 400) {
        // رسائل تحقق الخادم (إنجليزية) → رسالة الدخول المعتادة
        lastError.value = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      } else {
        lastError.value = apiErrorMessage(e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (registerUsernameCtrl.text.isEmpty ||
        registerFullNameCtrl.text.isEmpty ||
        registerPasswordCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'أدخل جميع البيانات المطلوبة', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (registerPasswordCtrl.text != registerConfirmCtrl.text) {
      Get.snackbar('خطأ', 'كلمتا المرور غير متطابقتين', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (registerPasswordCtrl.text.length < 8) {
      Get.snackbar('خطأ', 'كلمة المرور يجب أن تكون 8 أحرف على الأقل', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final deviceId = await _deviceService.getDeviceId();
      final response = await _authProvider.register(
        username: registerUsernameCtrl.text.trim(),
        fullName: registerFullNameCtrl.text.trim(),
        password: registerPasswordCtrl.text,
        deviceId: deviceId,
      );

      final data = response.data['data'];
      final token = data['token'] as String;
      final userData = UserModel.fromJson(data['user']);

      await _storage.saveToken(token);
      await _storage.saveUser(userData);
      user.value = userData;
      _syncScope(userData);

      Get.offAll(() => const StudentShell());
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'حدث خطأ أثناء التسجيل'),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAuth() async {
    if (_authChecked) return;
    _authChecked = true;

    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }

    try {
      final response = await _authProvider.getMe();
      final userData = UserModel.fromJson(response.data['data']);
      user.value = userData;
      await _storage.saveUser(userData);
      _syncScope(userData);

      if (userData.isAdmin) {
        Get.offAll(() => const AdminShell());
      } else if (userData.isTeacher) {
        Get.offAll(() => const TeacherShell());
      } else {
        Get.offAll(() => const StudentShell());
      }
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      if (status == 401 || status == 403) {
        // التوكن غير صالح فعليًا — الجلسة تنتهي ونطلب تسجيل الدخول
        await _storage.clearAll();
        _clearScope();
        if (Get.currentRoute != AppRoutes.login) {
          Get.offAllNamed(AppRoutes.login);
        }
        return;
      }
      // فشل شبكة أو سيرفر مؤقت — نُبقي الجلسة وندخل بالمستخدم المحفوظ محليًا
      final cached = await _storage.getUser();
      if (cached != null) {
        user.value = cached;
        _syncScope(cached);
        if (cached.isAdmin) {
          Get.offAll(() => const AdminShell());
        } else if (cached.isTeacher) {
          Get.offAll(() => const TeacherShell());
        } else {
          Get.offAll(() => const StudentShell());
        }
        return;
      }
      _authChecked = false;
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  Future<void> logout() async {
    _authChecked = false;
    try {
      await _authProvider.logoutAll();
    } catch (_) {}
    await _storage.clearAll();
    _clearScope();
    user.value = null;
    loginUsernameCtrl.clear();
    loginPasswordCtrl.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}
