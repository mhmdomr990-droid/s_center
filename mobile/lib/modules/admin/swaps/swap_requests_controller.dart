import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';

class SwapRequestsAdminController extends GetxController {
  final AdminProvider _provider;
  final isLoading = true.obs;
  final items = <Map<String, dynamic>>[].obs;
  final busy = false.obs;

  SwapRequestsAdminController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final res = await _provider.courseSwapRequests();
      final data = res.data['data'];
      if (data is List) {
        items.value = data
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تحميل طلبات التبديل'),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  String _decisionError(Object e) {
    final status = e is DioException ? e.response?.statusCode : null;
    switch (status) {
      case 404:
        return 'الطلب غير موجود';
      case 409:
        return 'الطلب لم يعد قيد الانتظار';
      default:
        return apiErrorMessage(e);
    }
  }

  Future<void> approve(Map<String, dynamic> item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('الموافقة على التبديل'),
        content: Text(
            'تبديل «${item['old_course_name']}» بـ«${item['new_course_name']}» للطالب ${item['student_name']}؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('موافقة')),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    busy.value = true;
    try {
      await _provider.approveCourseSwap((item['id'] as num).toInt());
      Get.snackbar('تم', 'تمت الموافقة على طلب التبديل',
          backgroundColor: AppColors.success, colorText: Colors.white);
      await load();
    } catch (e) {
      Get.snackbar('خطأ', _decisionError(e),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> reject(Map<String, dynamic> item) async {
    final reasonCtrl = TextEditingController();
    String? errorText;

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('رفض طلب التبديل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'تبديل «${item['old_course_name']}» بـ«${item['new_course_name']}»'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'سبب الرفض *',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  setState(() => errorText = 'أدخل سبب الرفض');
                  return;
                }
                Get.back(result: true);
              },
              child: const Text('رفض', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (confirmed != true) return;

    busy.value = true;
    try {
      await _provider.rejectCourseSwap((item['id'] as num).toInt(), reason: reason);
      Get.snackbar('تم', 'تم رفض طلب التبديل',
          backgroundColor: AppColors.success, colorText: Colors.white);
      await load();
    } catch (e) {
      Get.snackbar('خطأ', _decisionError(e),
          backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
