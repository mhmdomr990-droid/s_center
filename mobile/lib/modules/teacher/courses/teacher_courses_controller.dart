import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/teacher_provider.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/lecture_model.dart';

class TeacherCoursesController extends GetxController {
  final TeacherProvider _teacherProvider;

  TeacherCoursesController() : _teacherProvider = TeacherProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final isSaving = false.obs;
  final courses = <CourseModel>[].obs;
  final lectures = <LectureModel>[].obs;
  final currentCourse = Rxn<CourseModel>();

  @override
  void onInit() {
    super.onInit();
    loadCourses();
  }

  Future<void> loadCourses() async {
    isLoading.value = true;
    try {
      final response = await _teacherProvider.getCourses();
      final data = response.data['data'];
      if (data is List) {
        courses.value = data.map<CourseModel>((e) => CourseModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل الدورات', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCourseDetail(int courseId) async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _teacherProvider.getCourseById(courseId),
        _teacherProvider.getCourseLectures(courseId),
      ]);

      final courseData = results[0].data['data'];
      currentCourse.value = CourseModel.fromJson(courseData);

      final lectureData = results[1].data['data'];
      if (lectureData is List) {
        lectures.value = lectureData.map<LectureModel>((e) => LectureModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل تفاصيل الدورة', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDescription(int courseId, String description) async {
    isSaving.value = true;
    try {
      await _teacherProvider.updateCourseDescription(courseId, description);
      Get.snackbar('نجاح', 'تم تحديث الوصف', backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
      loadCourseDetail(courseId);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التحديث', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> createLecture(int courseId, {required String title, required String type, String? url, String? content, int? sortOrder}) async {
    isSaving.value = true;
    try {
      await _teacherProvider.createLecture(courseId, title: title, type: type, url: url, content: content, sortOrder: sortOrder);
      Get.back();
      Get.snackbar('نجاح', 'تم إضافة المحاضرة', backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
      loadCourseDetail(courseId);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إضافة المحاضرة', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateLecture(int lectureId, int courseId,
      {required String title, required String type, String? url, String? content, int? sortOrder}) async {
    isSaving.value = true;
    try {
      await _teacherProvider.updateLecture(lectureId,
          title: title, type: type, url: url, content: content, sortOrder: sortOrder);
      Get.back();
      Get.snackbar('نجاح', 'تم تحديث المحاضرة', backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
      loadCourseDetail(courseId);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث المحاضرة', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteLecture(int lectureId, int courseId) async {
    try {
      await _teacherProvider.deleteLecture(lectureId);
      Get.snackbar('نجاح', 'تم حذف المحاضرة', backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
      loadCourseDetail(courseId);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الحذف', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    }
  }

  Future<void> togglePublished(int lectureId, bool isPublished, int courseId) async {
    try {
      await _teacherProvider.toggleLecturePublished(lectureId, isPublished);
      loadCourseDetail(courseId);
    } catch (e) {
      // ignore
    }
  }
}
