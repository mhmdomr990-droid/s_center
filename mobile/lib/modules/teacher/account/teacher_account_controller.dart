import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/auth_provider.dart';
import '../../auth/auth_controller.dart';

class TeacherAccountController extends GetxController {
  final AuthController auth = Get.find<AuthController>();
  final AuthProvider _authProvider;
  final isChangingPassword = false.obs;

  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  TeacherAccountController() : _authProvider = AuthProvider(Get.find<ApiClient>());

  @override
  void onClose() {
    oldPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }

  Future<void> changePassword() async {
    oldPasswordCtrl.clear();
    newPasswordCtrl.clear();
    confirmCtrl.clear();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة (8 أحرف على الأقل)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور الجديدة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('حفظ')),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    if (oldPasswordCtrl.text.isEmpty || newPasswordCtrl.text.length < 8) {
      Get.snackbar('خطأ', 'أدخل كلمة المرور الحالية والجديدة (8 أحرف على الأقل)',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (newPasswordCtrl.text != confirmCtrl.text) {
      Get.snackbar('خطأ', 'تأكيد كلمة المرور غير مطابق',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    isChangingPassword.value = true;
    try {
      await _authProvider.changePassword(
          oldPassword: oldPasswordCtrl.text, newPassword: newPasswordCtrl.text);
      oldPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmCtrl.clear();
      Get.snackbar('تم', 'تم تغيير كلمة المرور بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isChangingPassword.value = false;
    }
  }

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد الخروج من حساب المعلم؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;
    await auth.logout();
  }
}
