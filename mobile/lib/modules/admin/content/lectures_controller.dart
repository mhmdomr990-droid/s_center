import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/services/video_compressor.dart';

class LecturesController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final busy = false.obs;
  final uploadProgress = 0.0.obs;
  final compressing = false.obs;
  final compressProgress = 0.0.obs;
  final compressEta = 0.obs;
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
    uploadProgress.value = 0;
    compressing.value = false;
    compressProgress.value = 0;
    compressEta.value = 0;
    var uploadPath = videoFilePath;
    String? compressSummary;
    try {
      if (compress && videoFilePath != null && type == 'VIDEO' && !kIsWeb) {
        compressing.value = true;
        final outcome = await VideoCompressor.compressForUpload(
          videoFilePath,
          onProgress: (p) => compressProgress.value = p,
          onEta: (s) => compressEta.value = s,
        );
        compressing.value = false;
        compressProgress.value = 0;
    compressEta.value = 0;
        uploadPath = outcome.path ?? videoFilePath;
        compressSummary = outcome.summary;
        debugPrint(
            'compress: ${outcome.reason} ${outcome.sourceSize} -> ${outcome.outputSize ?? '-'} ${outcome.error ?? ''}');
      }
      await _provider.createLecture(
        courseId: courseId,
        title: title,
        type: type,
        url: url,
        content: content,
        sortOrder: sortOrder,
        videoFilePath: uploadPath,
        fileBytes: fileBytes,
        fileName: fileName,
        onSendProgress: uploadPath != null
            ? (sent, total) {
                if (total > 0) uploadProgress.value = (sent / total).clamp(0.0, 1.0);
              }
            : null,
      );
      Get.snackbar(
        'تم',
        videoFilePath != null
            ? 'تم رفع الملف بنجاح ✓${compressSummary == null ? '' : '\n$compressSummary'}'
            : 'تم إنشاء المحاضرة',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await loadLectures();
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        apiErrorMessage(e,
            fallback: videoFilePath != null ? 'فشل رفع الملف' : 'فشل إنشاء المحاضرة'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      busy.value = false;
      uploadProgress.value = 0;
      compressing.value = false;
      compressProgress.value = 0;
    compressEta.value = 0;
      if (videoFilePath != null) await VideoCompressor.deleteCache();
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
    uploadProgress.value = 0;
    compressing.value = false;
    compressProgress.value = 0;
    compressEta.value = 0;
    var uploadPath = videoFilePath;
    String? compressSummary;
    try {
      if (compress && videoFilePath != null && type == 'VIDEO' && !kIsWeb) {
        compressing.value = true;
        final outcome = await VideoCompressor.compressForUpload(
          videoFilePath,
          onProgress: (p) => compressProgress.value = p,
          onEta: (s) => compressEta.value = s,
        );
        compressing.value = false;
        compressProgress.value = 0;
    compressEta.value = 0;
        uploadPath = outcome.path ?? videoFilePath;
        compressSummary = outcome.summary;
        debugPrint(
            'compress: ${outcome.reason} ${outcome.sourceSize} -> ${outcome.outputSize ?? '-'} ${outcome.error ?? ''}');
      }
      await _provider.updateLecture(
        id,
        title: title,
        type: type,
        url: url,
        content: content,
        sortOrder: sortOrder,
        videoFilePath: uploadPath,
        fileBytes: fileBytes,
        fileName: fileName,
        onSendProgress: uploadPath != null
            ? (sent, total) {
                if (total > 0) uploadProgress.value = (sent / total).clamp(0.0, 1.0);
              }
            : null,
      );
      Get.snackbar(
        'تم',
        videoFilePath != null
            ? 'تم رفع الملف بنجاح ✓${compressSummary == null ? '' : '\n$compressSummary'}'
            : 'تم تحديث المحاضرة',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await loadLectures();
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        apiErrorMessage(e,
            fallback: videoFilePath != null ? 'فشل رفع الملف' : 'فشل تحديث المحاضرة'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      busy.value = false;
      uploadProgress.value = 0;
      compressing.value = false;
      compressProgress.value = 0;
    compressEta.value = 0;
      if (videoFilePath != null) await VideoCompressor.deleteCache();
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
