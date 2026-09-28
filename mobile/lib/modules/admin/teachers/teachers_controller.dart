import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../app/routes/app_routes.dart';

class TeachersController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final busy = false.obs;
  final items = <Map<String, dynamic>>[].obs;

  final usernameCtrl = TextEditingController();
  final fullNameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  TeachersController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    fullNameCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await _provider.teachers();
      items.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTeacher({
    required String username,
    required String fullName,
    required String password,
  }) async {
    busy.value = true;
    try {
      await _provider.createTeacher(username: username, fullName: fullName, password: password);
      Get.snackbar('تم', 'تم إنشاء حساب المعلم', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل إنشاء المعلم — تحقق من البيانات (اسم مستخدم متفرد؟)',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  void openDetail(int teacherId) {
    Get.toNamed(AppRoutes.adminTeacherDetail, arguments: {'teacherId': teacherId});
  }
}
