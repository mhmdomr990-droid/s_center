import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/teacher_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/catalog_lookup.dart';
import '../../../data/models/course_model.dart';

class TeacherHomeController extends GetxController {
  final TeacherProvider _teacherProvider;
  final StorageService _storage;

  TeacherHomeController()
      : _teacherProvider = TeacherProvider(Get.find<ApiClient>()),
        _storage = Get.find<StorageService>();

  final isLoading = true.obs;
  final userName = ''.obs;
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
    _loadUserName();
    loadDashboard();
  }

  Future<void> _loadUserName() async {
    final user = await _storage.getUser();
    final name = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (user?.username ?? '');
    userName.value = name;
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
        await CatalogLookup.ensureLoaded();
        courses.value = coursesData.map<CourseModel>((e) {
          final json = Map<String, dynamic>.from(e as Map);
          return CourseModel.fromJson(CatalogLookup.enrichJson(json));
        }).toList();
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
