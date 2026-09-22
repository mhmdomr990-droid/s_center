import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/providers/api_client.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/device_service.dart';
import '../../data/models/user_model.dart';
import '../../app/routes/app_routes.dart';
import '../home_shell.dart';

class AuthController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final StorageService _storage = Get.find<StorageService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  late final AuthProvider _authProvider;

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final user = Rxn<UserModel>();
  bool _authChecked = false;

  final loginUsernameCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();
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

      await _storage.saveToken(token);
      await _storage.saveUser(userData);
      user.value = userData;

      if (userData.isTeacher) {
        Get.offAll(() => const TeacherShell());
      } else {
        Get.offAll(() => const StudentShell());
      }
    } catch (e) {
      String msg = 'حدث خطأ';
      if (e.toString().contains('401') || e.toString().contains('Invalid')) {
        msg = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      } else if (e.toString().contains('403')) {
        msg = 'الحساب مرتبط بجهاز آخر';
      }
      Get.snackbar('خطأ', msg, backgroundColor: Colors.red, colorText: Colors.white);
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

      Get.offAll(() => const StudentShell());
    } catch (e) {
      String msg = 'حدث خطأ أثناء التسجيل';
      if (e.toString().contains('409') || e.toString().contains('already')) {
        msg = 'اسم المستخدم مستخدم بالفعل';
      }
      Get.snackbar('خطأ', msg, backgroundColor: Colors.red, colorText: Colors.white);
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

      if (userData.isTeacher) {
        Get.offAll(() => const TeacherShell());
      } else {
        Get.offAll(() => const StudentShell());
      }
    } catch (e) {
      await _storage.clearAll();
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
    user.value = null;
    loginUsernameCtrl.clear();
    loginPasswordCtrl.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}
