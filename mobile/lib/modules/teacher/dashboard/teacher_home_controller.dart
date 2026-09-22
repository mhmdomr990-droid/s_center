import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/teacher_provider.dart';
import '../../../data/models/course_model.dart';

class TeacherHomeController extends GetxController {
  final TeacherProvider _teacherProvider;

  TeacherHomeController() : _teacherProvider = TeacherProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final totalPurchases = 0.obs;
  final totalEarned = '0.00'.obs;
  final totalPaid = '0.00'.obs;
  final remaining = '0.00'.obs;
  final courses = <CourseModel>[].obs;
  final dailySales = <Map<String, dynamic>>[].obs;
  final selectedDays = 30.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      final response = await _teacherProvider.getDashboard(days: selectedDays.value);
      final data = response.data['data'];

      totalPurchases.value = data['total_purchases'] ?? 0;
      totalEarned.value = (data['total_earned'] ?? '0.00').toString();
      totalPaid.value = (data['total_paid'] ?? '0.00').toString();
      remaining.value = (data['remaining'] ?? '0.00').toString();

      final coursesData = data['per_course'];
      if (coursesData is List) {
        courses.value = coursesData.map<CourseModel>((e) => CourseModel.fromJson(e)).toList();
      }

      final dailyData = data['daily_sales'];
      if (dailyData is List) {
        dailySales.value = dailyData.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل لوحة التحكم', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
