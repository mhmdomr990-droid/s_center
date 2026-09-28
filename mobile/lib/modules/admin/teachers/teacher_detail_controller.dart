import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';

class TeacherDetailController extends GetxController {
  final AdminProvider _provider;
  final isLoading = true.obs;
  final busy = false.obs;
  final teacher = Rxn<Map<String, dynamic>>();
  final courses = <Map<String, dynamic>>[].obs;
  final payouts = <Map<String, dynamic>>[].obs;

  late final int teacherId;

  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  TeacherDetailController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    teacherId = (Get.arguments as Map)['teacherId'] as int;
    load();
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await _provider.teacherById(teacherId);
      final data = Map<String, dynamic>.from(response.data['data']);
      teacher.value = data;
      courses.assignAll(List<Map<String, dynamic>>.from(
          ((data['courses'] ?? []) as List).map((e) => Map<String, dynamic>.from(e))));
      payouts.assignAll(List<Map<String, dynamic>>.from(
          ((data['payouts'] ?? []) as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل بيانات المعلم',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPayout() async {
    amountCtrl.clear();
    noteCtrl.clear();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تسجيل دفعة للمعلم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ (SYP)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('تسجيل')),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    final amount = amountCtrl.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      Get.snackbar('خطأ', 'أدخل مبلغاً صحيحاً', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    busy.value = true;
    try {
      await _provider.createTeacherPayout(teacherId,
          amount: amount, note: noteCtrl.text.trim());
      Get.snackbar('تم', 'تم تسجيل الدفعة', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تسجيل الدفعة', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
