import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';

class LecturesController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final busy = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final courses = <Map<String, dynamic>>[].obs;
  final selectedCourseId = RxnInt();

  LecturesController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      final response = await _provider.courses(limit: 100);
      courses.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
      if (selectedCourseId.value == null && courses.isNotEmpty) {
        selectedCourseId.value = courses.first['id'] as int;
        await loadLectures();
      }
    } catch (_) {}
  }

  Future<void> selectCourse(int? courseId) async {
    selectedCourseId.value = courseId;
    await loadLectures();
  }

  Future<void> loadLectures() async {
    final courseId = selectedCourseId.value;
    isLoading.value = true;
    try {
      final response = await _provider.lectures(courseId: courseId);
      items.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createLecture(Map<String, dynamic> body) async {
    busy.value = true;
    try {
      await _provider.createLecture(body);
      Get.snackbar('تم', 'تم إنشاء المحاضرة', backgroundColor: Colors.green, colorText: Colors.white);
      await loadLectures();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل إنشاء المحاضرة — تحقق من البيانات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> updateLecture(int id, Map<String, dynamic> body) async {
    busy.value = true;
    try {
      await _provider.updateLecture(id, body);
      Get.snackbar('تم', 'تم تحديث المحاضرة', backgroundColor: Colors.green, colorText: Colors.white);
      await loadLectures();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تحديث المحاضرة', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> togglePublished(Map<String, dynamic> item) async {
    busy.value = true;
    try {
      await _provider.setLecturePublished(
          item['id'] as int, isPublished: !(item['is_published'] ?? true));
      await loadLectures();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تغيير حالة النشر', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> delete(Map<String, dynamic> item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('حذف المحاضرة'),
        content: Text('سيتم حذف "${item['title']}" نهائياً. متابعة؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    busy.value = true;
    try {
      await _provider.deleteLecture(item['id'] as int);
      Get.snackbar('تم', 'تم حذف المحاضرة', backgroundColor: Colors.green, colorText: Colors.white);
      await loadLectures();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل حذف المحاضرة', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
