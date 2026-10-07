import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/teacher_provider.dart';
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
  final teacherCoursesCount = 0.obs;
  final teacherTotalEarned = '0.00'.obs;

  /// أسماء الاختصاصات (مسار عام) لعرض اسم تخصص الطالب — صامت عند الفشل
  final specNames = <int, String>{}.obs;

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
    unawaited(_loadSpecNames());
  }

  Future<void> _loadSpecNames() async {
    try {
      final provider = CatalogProvider(Get.find<ApiClient>());
      final response = await provider.getSpecializations();
      final data = response.data['data'];
      if (data is List) {
        specNames.value = {
          for (final e in data)
            ((e['id'] as num?)?.toInt() ?? 0): (e['name'] ?? '').toString()
        };
      }
    } catch (_) {
      // زخرفة فقط — الاسم يظهر إن توفّر وإلا يُخفى
    }
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

      if (userData.isTeacher) {
        _loadTeacherStats();
      }
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'تعذر تحميل بيانات الحساب'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTeacherStats() async {
    final teacherProvider = TeacherProvider(Get.find<ApiClient>());
    try {
      final response = await teacherProvider.getStats();
      final stats = response.data['data'];
      teacherTotalEarned.value = (stats['total_earned'] ?? '0.00').toString();
    } catch (_) {
      // ignore — stats are optional decoration on the card
    }
    try {
      // العدّ يشمل كل دورات المعلّم (meta.total) لا المباعة فقط
      final response = await teacherProvider.getCourses();
      final total = response.data['meta']?['total'];
      final list = response.data['data'];
      teacherCoursesCount.value = total is num
          ? total.toInt()
          : (list is List ? list.length : 0);
    } catch (_) {
      // ignore — count is optional decoration on the card
    }
  }

  Future<void> changePassword() async {
    oldPasswordCtrl.clear();
    newPasswordCtrl.clear();
    confirmPasswordCtrl.clear();

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
              controller: confirmPasswordCtrl,
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

    final oldPass = oldPasswordCtrl.text;
    final newPass = newPasswordCtrl.text;
    final confirmPass = confirmPasswordCtrl.text;

    if (oldPass.isEmpty || newPass.length < 8) {
      Get.snackbar('خطأ', 'أدخل كلمة المرور الحالية والجديدة (8 أحرف على الأقل)',
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
