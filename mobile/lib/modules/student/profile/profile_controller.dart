import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../auth/auth_controller.dart';

class ProfileController extends GetxController {
  final AuthProvider _authProvider;
  final StorageService _storage;

  ProfileController()
      : _authProvider = AuthProvider(Get.find<ApiClient>()),
        _storage = Get.find<StorageService>();

  final isLoading = false.obs;
  final isChangingPassword = false.obs;
  final isLoggingOut = false.obs;
  final user = Rxn<UserModel>();

  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final obscureOld = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    oldPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final response = await _authProvider.getMe();
      final userData = UserModel.fromJson(response.data['data']);
      user.value = userData;
      await _storage.saveUser(userData);
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'تعذر تحميل بيانات الحساب'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changePassword() async {
    final oldPass = oldPasswordCtrl.text;
    final newPass = newPasswordCtrl.text;
    final confirmPass = confirmPasswordCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      Get.snackbar('خطأ', 'أدخل جميع الحقول', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }
    if (newPass.length < 8) {
      Get.snackbar('خطأ', 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل',
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }
    if (newPass != confirmPass) {
      Get.snackbar('خطأ', 'تأكيد كلمة المرور غير مطابق', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }

    isChangingPassword.value = true;
    try {
      await _authProvider.changePassword(oldPassword: oldPass, newPassword: newPass);
      oldPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();
      Get.snackbar('نجاح', 'تم تغيير كلمة المرور بنجاح',
          backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e), backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isChangingPassword.value = false;
    }
  }

  Future<void> logout({bool fromAllDevices = false}) async {
    if (isLoggingOut.value) return;

    if (fromAllDevices) {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('تسجيل الخروج من كل الأجهزة'),
          content: const Text('سيتم إلغاء صلاحية الجلسات على جميع الأجهزة. هل أنت متأكد؟'),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('تأكيد', style: TextStyle(color: Color(0xFFE53935))),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    isLoggingOut.value = true;
    try {
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().logout();
      } else {
        await _storage.clearAll();
        Get.offAllNamed(AppRoutes.login);
      }
    } finally {
      isLoggingOut.value = false;
    }
  }
}
