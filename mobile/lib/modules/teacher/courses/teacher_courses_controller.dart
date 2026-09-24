import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/teacher_provider.dart';
import '../../../data/services/catalog_lookup.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/lecture_model.dart';
import '../../../data/models/specialization_model.dart';

class TeacherCoursesController extends GetxController {
  final TeacherProvider _teacherProvider;
  final CatalogProvider _catalogProvider;

  TeacherCoursesController()
      : _teacherProvider = TeacherProvider(Get.find<ApiClient>()),
        _catalogProvider = CatalogProvider(Get.find<ApiClient>());

  static const List<int> availableYears = [1, 2, 3, 4, 5];

  final isLoading = true.obs;
  final isSaving = false.obs;
  final courses = <CourseModel>[].obs;
  final specializations = <SpecializationModel>[].obs;
  final selectedSpecializationId = Rxn<int>();
  final selectedYear = Rxn<int>();
  final lectures = <LectureModel>[].obs;
  final currentCourse = Rxn<CourseModel>();

  List<CourseModel> get filteredCourses => courses.where((course) {
        final specOk = selectedSpecializationId.value == null ||
            course.specializationId == selectedSpecializationId.value;
        final yearOk =
            selectedYear.value == null || course.year == selectedYear.value;
        return specOk && yearOk;
      }).toList();

  String get filterTitle {
    final specName = selectedSpecializationId.value == null
        ? 'كل الاختصاصات'
        : (specializations
                .firstWhereOrNull((s) => s.id == selectedSpecializationId.value)
                ?.name ??
            'اختصاص');
    final yearLabel = selectedYear.value == null
        ? 'كل السنوات'
        : 'السنة ${selectedYear.value}';
    return '$specName — $yearLabel';
  }

  bool get hasActiveFilter =>
      selectedSpecializationId.value != null || selectedYear.value != null;

  @override
  void onInit() {
    super.onInit();
    loadCourses();
  }

  void selectSpecialization(int? specId) {
    if (selectedSpecializationId.value == specId) return;
    selectedSpecializationId.value = specId;
    courses.refresh();
  }

  void selectYear(int? year) {
    if (selectedYear.value == year) return;
    selectedYear.value = year;
    courses.refresh();
  }

  Future<void> loadCourses() async {
    isLoading.value = true;
    try {
      await CatalogLookup.ensureLoaded();
      final results = await Future.wait([
        _teacherProvider.getCourses(),
        _catalogProvider.getSpecializations(),
      ]);

      final specData = results[1].data['data'];
      if (specData is List) {
        specializations.value = specData
            .map<SpecializationModel>((e) => SpecializationModel.fromJson(e))
            .toList();
      }

      final data = results[0].data['data'];
      if (data is List) {
        courses.value = data.map<CourseModel>((e) {
          final json = Map<String, dynamic>.from(e as Map);
          return CourseModel.fromJson(CatalogLookup.enrichJson(json));
        }).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل الدورات',
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCourseDetail(int courseId) async {
    isLoading.value = true;
    try {
      await CatalogLookup.ensureLoaded();
      final results = await Future.wait([
        _teacherProvider.getCourseById(courseId),
        _teacherProvider.getCourseLectures(courseId),
      ]);

      final courseData = results[0].data['data'];
      currentCourse.value =
          CourseModel.fromJson(CatalogLookup.enrichJson(courseData));

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
