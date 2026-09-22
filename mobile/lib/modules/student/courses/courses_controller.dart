import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/purchase_provider.dart';
import '../../../data/models/specialization_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/lecture_model.dart';

class CoursesController extends GetxController {
  final CatalogProvider _catalogProvider;
  final PurchaseProvider _purchaseProvider;

  CoursesController()
      : _catalogProvider = CatalogProvider(Get.find<ApiClient>()),
        _purchaseProvider = PurchaseProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final isPurchasing = false.obs;
  final specializations = <SpecializationModel>[].obs;
  final courses = <CourseModel>[].obs;
  final lectures = <LectureModel>[].obs;
  final selectedSpecializationId = Rxn<int>();
  final selectedYear = Rxn<int>();
  final currentCourse = Rxn<CourseModel>();

  @override
  void onInit() {
    super.onInit();
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _catalogProvider.getSpecializations(),
        _catalogProvider.getCourses(),
      ]);

      final specData = results[0].data['data'];
      if (specData is List) {
        specializations.value = specData.map<SpecializationModel>((e) => SpecializationModel.fromJson(e)).toList();
      }

      final courseData = results[1].data['data'];
      if (courseData is List) {
        courses.value = courseData.map<CourseModel>((e) => CourseModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تحميل الكتالوج'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> filterBySpecialization(int? specId) async {
    selectedSpecializationId.value = specId;
    isLoading.value = true;
    try {
      final response = await _catalogProvider.getCourses(
        specializationId: specId,
        year: selectedYear.value,
      );
      final courseData = response.data['data'];
      if (courseData is List) {
        courses.value = courseData.map<CourseModel>((e) => CourseModel.fromJson(e)).toList();
      }
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCourseDetail(int courseId) async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _catalogProvider.getCourses(),
        _catalogProvider.getCourseLectures(courseId),
      ]);

      final courseData = results[0].data['data'];
      if (courseData is List) {
        final found = courseData.firstWhereOrNull((e) => (e['id'] ?? 0) == courseId);
        if (found != null) currentCourse.value = CourseModel.fromJson(found);
      }

      final lectureData = results[1].data['data'];
      if (lectureData is List) {
        lectures.value = lectureData.map<LectureModel>((e) => LectureModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تحميل تفاصيل الدورة'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> purchaseCourse(int courseId) async {
    isPurchasing.value = true;
    try {
      await _purchaseProvider.purchaseCourse(courseId);
      Get.back();
      Get.snackbar('نجاح', 'تم شراء الدورة بنجاح', backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
      loadCourseDetail(courseId);
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل الشراء'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isPurchasing.value = false;
    }
  }
}
