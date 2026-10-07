import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import 'courses_controller.dart';

class SpecializationsController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final busy = false.obs;

  final nameCtrl = TextEditingController();

  SpecializationsController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await _provider.specializations();
      items.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> create() async {
    nameCtrl.clear();
    final confirmed = await _dialog('إضافة تخصص', 'اسم التخصص');
    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    busy.value = true;
    try {
      await _provider.createSpecialization(name: name);
      Get.snackbar('تم', 'تمت إضافة التخصص', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshCoursesMeta();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل إضافة التخصص', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> edit(Map<String, dynamic> item) async {
    nameCtrl.text = item['name'] ?? '';
    final confirmed = await _dialog('تعديل التخصص', 'اسم التخصص');
    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty || name == item['name']) return;

    busy.value = true;
    try {
      await _provider.updateSpecialization(item['id'] as int, name: name);
      Get.snackbar('تم', 'تم تعديل التخصص', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshCoursesMeta();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تعديل التخصص', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> togglePublished(Map<String, dynamic> item) async {
    busy.value = true;
    try {
      await _provider.setSpecializationPublished(
          item['id'] as int, isPublished: !(item['is_published'] ?? true));
      await load();
      _refreshCoursesMeta();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تغيير حالة النشر', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  void _refreshCoursesMeta() {
    if (Get.isRegistered<CoursesController>()) {
      Get.find<CoursesController>().loadMeta();
    }
  }

  Future<bool?> _dialog(String title, String label) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('حفظ')),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
