import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/services/upload_manager.dart';

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

  Future<bool> createLecture({
    required int courseId,
    required String title,
    required String type,
    String? url,
    String? content,
    int? sortOrder,
    String? videoFilePath,
    Uint8List? fileBytes,
    String? fileName,
    bool compress = true,
  }) async {
    busy.value = true;
    try {
      final ok = await Get.find<UploadManager>().run(UploadTask(
        courseId: courseId,
        title: title,
        type: type,
        url: url,
        content: content,
        sortOrder: sortOrder,
        videoFilePath: videoFilePath,
        fileBytes: fileBytes,
        fileName: fileName,
        compress: compress,
        successMessage:
            videoFilePath != null ? 'تم رفع الملف بنجاح ✓' : 'تم إنشاء المحاضرة',
        failMessage: videoFilePath != null ? 'فشل رفع الملف' : 'فشل إنشاء المحاضرة',
        upload: (path, onSend) => _provider.createLecture(
          courseId: courseId,
          title: title,
          type: type,
          url: url,
          content: content,
          sortOrder: sortOrder,
          videoFilePath: path,
          fileBytes: fileBytes,
          fileName: fileName,
          onSendProgress: onSend,
        ),
      ));
      if (ok) await loadLectures();
      return ok;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> updateLecture(
    int id, {
    required String title,
    required String type,
    String? url,
    String? content,
    int? sortOrder,
    String? videoFilePath,
    Uint8List? fileBytes,
    String? fileName,
    bool compress = true,
  }) async {
    busy.value = true;
    try {
      final ok = await Get.find<UploadManager>().run(UploadTask(
        isEdit: true,
        lectureId: id,
        courseId: 0,
        title: title,
        type: type,
        url: url,
        content: content,
        sortOrder: sortOrder,
        videoFilePath: videoFilePath,
        fileBytes: fileBytes,
        fileName: fileName,
        compress: compress,
        successMessage:
            videoFilePath != null ? 'تم رفع الملف بنجاح ✓' : 'تم تحديث المحاضرة',
        failMessage: videoFilePath != null ? 'فشل رفع الملف' : 'فشل تحديث المحاضرة',
        upload: (path, onSend) => _provider.updateLecture(
          id,
          title: title,
          type: type,
          url: url,
          content: content,
          sortOrder: sortOrder,
          videoFilePath: path,
          fileBytes: fileBytes,
          fileName: fileName,
          onSendProgress: onSend,
        ),
      ));
      if (ok) await loadLectures();
      return ok;
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
