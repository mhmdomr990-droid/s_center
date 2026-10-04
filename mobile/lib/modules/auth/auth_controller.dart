import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // حقل عنوان الخادم في شاشتي الدخول والتسجيل — مصدر العنوان الوحيد
  // يعرض العنوان المحفوظ كما هو حرفياً
  final ipCtrl = TextEditingController(text: ApiClient.baseUrl);

  static final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

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

  // تطبيع ما يكتبه المستخدم — بالحد الأدنى ولا شيء غير ذلك:
  // 1) يضيف http:// إن لم تكتب الصيغة
  // 2) يضيف :3000 لـ IP/localhost فقط إن لم يكتب منفذاً (النطاقات لا تُمس)
  // 3) يضيف /api إن لم ينتهِ بها
  // وكل ما كتبه المستخدم يبقى كما هو (العملية لا دائرية عند إعادة الإرسال)
  static String? _normalizeBase(String input) {
    var v = input.trim();
    if (v.isEmpty) return null;
    if (RegExp(r'\s').hasMatch(v)) return null; // نص حر بمسافات — ليس عنواناً
    final lower = v.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      v = 'http://$v';
    }
    var uri = Uri.tryParse(v);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    // منفذ 3000 فقط لـ IP أو localhost حين لا يذكر المستخدم منفذاً
    if (!uri.hasPort && (uri.host == 'localhost' || _ipv4.hasMatch(uri.host))) {
      uri = uri.replace(port: 3000);
    }
    if (!uri.path.endsWith('/api')) {
      var p = uri.path;
      while (p.endsWith('/')) {
        p = p.substring(0, p.length - 1);
      }
      uri = uri.replace(path: '$p/api');
    }
    return uri.toString();
  }

  // تطبيق عنوان الخادم المختار — مصدره حقل ipCtrl دائماً.
  // يرجع false عند حقل فارغ أو عنوان غير صالح (لا يستمر الدخول/التسجيل)
  Future<bool> _applyServerHost() async {
    final host = ipCtrl.text.trim();
    if (host.isEmpty) {
      Get.snackbar('خطأ', 'أدخل عنوان الخادم — مثال: 10.42.0.1:3000 أو https://example.com',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    final base = _normalizeBase(host);
    if (base == null) {
      Get.snackbar(
          'خطأ', 'عنوان غير صالح — مثال: 192.168.1.10:3000 أو https://example.com',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiClient.overrideKey, base);
    } catch (_) {}
    _apiClient.applyBaseUrl(base);
    return true;
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
    ipCtrl.dispose();
    registerUsernameCtrl.dispose();
    registerFullNameCtrl.dispose();
    registerPasswordCtrl.dispose();
    registerConfirmCtrl.dispose();
    super.onClose();
  }

  Future<void> login() async {
    // تطبيق عنوان الخادم قبل أي طلب — حقل فارغ يمنع الدخول
    if (!await _applyServerHost()) return;

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
      lastError.value = apiErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    // تطبيق عنوان الخادم (حقل شاشة التسجيل) قبل أي طلب
    if (!await _applyServerHost()) return;

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

    // لا عنوان خادم بعد (تثبيت جديد أو مسح البيانات) — نذهب للشاشة لإدخاله
    if (ApiClient.baseUrl.isEmpty) {
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
