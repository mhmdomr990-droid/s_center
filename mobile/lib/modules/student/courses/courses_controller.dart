import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/purchase_provider.dart';
import '../../../data/models/specialization_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/lecture_model.dart';
import '../../../data/services/offline_cache.dart';
import '../notifications/notifications_controller.dart';

class CoursesController extends GetxController {
  final CatalogProvider _catalogProvider;
  final PurchaseProvider _purchaseProvider;

  CoursesController()
      : _catalogProvider = CatalogProvider(Get.find<ApiClient>()),
        _purchaseProvider = PurchaseProvider(Get.find<ApiClient>());

  static const List<int> availableYears = [1, 2, 3, 4, 5];

  final isLoading = true.obs;
  final isLoadingDetail = false.obs;
  final isPurchasing = false.obs;
  final detailError = Rxn<String>();
  final specializations = <SpecializationModel>[].obs;
  final courses = <CourseModel>[].obs;
  final lectures = <LectureModel>[].obs;
  final selectedSpecializationId = Rxn<int>();
  final selectedYear = Rxn<int>();
  final currentCourse = Rxn<CourseModel>();
  final purchasedIds = <int>{}.obs;
  final offlineFallback = false.obs;
  final detailOffline = false.obs;

  Map<int, String> _specNames = {};

  bool isPurchased(int courseId) => purchasedIds.contains(courseId);

  String get filterTitle {
    final specName = selectedSpecializationId.value == null
        ? 'كل الاختصاصات'
        : (specializations
                .firstWhereOrNull((s) => s.id == selectedSpecializationId.value)
                ?.name ??
            'اختصاص');
    final yearLabel = selectedYear.value == null ? 'كل السنوات' : 'السنة ${selectedYear.value}';
    return '$specName — $yearLabel';
  }

  @override
  void onInit() {
    super.onInit();
    loadCatalog();
  }

  List<CourseModel> _parseCourses(dynamic courseData) {
    if (courseData is! List) return [];
    return courseData.map<CourseModel>((e) {
      final json = Map<String, dynamic>.from(e as Map);
      if ((json['specialization_name'] == null || json['specialization_name'] == '') &&
          _specNames.containsKey(json['specialization_id'])) {
        json['specialization_name'] = _specNames[json['specialization_id']];
      }
      final course = CourseModel.fromJson(json);
      if (course.isPurchased) purchasedIds.add(course.id);
      return course;
    }).toList();
  }

  Future<void> loadCatalog() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _catalogProvider.getSpecializations(),
        _catalogProvider.getCourses(
          specializationId: selectedSpecializationId.value,
          year: selectedYear.value,
        ),
      ]);

      final specData = results[0].data['data'];
      if (specData is List) {
        specializations.value =
            specData.map<SpecializationModel>((e) => SpecializationModel.fromJson(e)).toList();
        _specNames = {for (final s in specializations) s.id: s.name};
      }

      courses.value = _parseCourses(results[1].data['data']);
      if (specData is List && results[1].data['data'] is List) {
        unawaited(OfflineCache.saveCatalog(
            specData, results[1].data['data'] as List));
      }
      offlineFallback.value = false;
    } catch (e) {
      final cached = await OfflineCache.loadCatalog();
      if (cached != null && cached['specializations'] is List && cached['courses'] is List) {
        specializations.value = (cached['specializations'] as List)
            .map<SpecializationModel>(
                (e) => SpecializationModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _specNames = {for (final s in specializations) s.id: s.name};
        courses.value = _parseCourses(cached['courses']);
        offlineFallback.value = true;
        Get.snackbar('غير متصل', 'عُرضت آخر بيانات محفوظة',
            backgroundColor: const Color(0xFFFFA000), colorText: Color(0xFFFFFFFF));
      } else {
        Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تحميل الكتالوج'),
            backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> applyFilters() async {
    isLoading.value = true;
    try {
      final response = await _catalogProvider.getCourses(
        specializationId: selectedSpecializationId.value,
        year: selectedYear.value,
      );
      courses.value = _parseCourses(response.data['data']);
      offlineFallback.value = false;
    } catch (e) {
      final cached = await OfflineCache.loadCatalog();
      if (cached != null && cached['courses'] is List) {
        courses.value = _parseCourses(cached['courses']).where((c) {
          final okSpec = selectedSpecializationId.value == null ||
              c.specializationId == selectedSpecializationId.value;
          final okYear =
              selectedYear.value == null || c.year == selectedYear.value;
          return okSpec && okYear;
        }).toList();
        offlineFallback.value = true;
        Get.snackbar('غير متصل', 'عُرضت نتائج محفوظة من آخر اتصال',
            backgroundColor: const Color(0xFFFFA000), colorText: Color(0xFFFFFFFF));
      } else {
        Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تطبيق الفلتر'),
            backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectSpecialization(int? specId) {
    if (selectedSpecializationId.value == specId) return;
    selectedSpecializationId.value = specId;
    applyFilters();
  }

  void selectYear(int? year) {
    if (selectedYear.value == year) return;
    selectedYear.value = year;
    applyFilters();
  }

  Map<String, dynamic> _courseJson(CourseModel c) => {
        'id': c.id,
        'specialization_id': c.specializationId,
        'specialization_name': c.specializationName,
        'teacher_id': c.teacherId,
        'teacher_full_name': c.teacherName,
        'teacher_percent': c.teacherPercent,
        'year': c.year,
        'name': c.name,
        'description': c.description,
        'price': c.price,
        'is_published': c.isPublished,
        'sort_order': c.sortOrder,
        'purchased': c.isPurchased,
      };

  Future<void> loadCourseDetail(int courseId, {CourseModel? course}) async {
    if (course != null) {
      currentCourse.value = course;
    } else {
      currentCourse.value =
          courses.firstWhereOrNull((c) => c.id == courseId) ?? currentCourse.value;
    }
    lectures.clear();
    detailError.value = null;
    isLoadingDetail.value = true;
    try {
      final response = await _catalogProvider.getCourseLectures(courseId);
      final lectureData = response.data['data'];
      if (lectureData is List) {
        lectures.value = lectureData.map<LectureModel>((e) => LectureModel.fromJson(e)).toList();
        final c = currentCourse.value;
        if (c != null && c.id == courseId) {
          unawaited(OfflineCache.saveCourseDetail(
              courseId, _courseJson(c), lectureData));
        }
      }
      detailOffline.value = false;
    } catch (e) {
      final cached = await OfflineCache.loadCourseDetail(courseId);
      if (cached != null && cached['lectures'] is List) {
        if (currentCourse.value?.id != courseId && cached['course'] is Map) {
          currentCourse.value = CourseModel.fromJson(
              Map<String, dynamic>.from(cached['course'] as Map));
        }
        lectures.value = (cached['lectures'] as List)
            .map<LectureModel>(
                (e) => LectureModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        detailOffline.value = true;
        Get.snackbar('غير متصل', 'عُرضت آخر بيانات محفوظة لهذه الدورة',
            backgroundColor: const Color(0xFFFFA000), colorText: Color(0xFFFFFFFF));
      } else {
        detailError.value = apiErrorMessage(e, fallback: 'فشل تحميل المحاضرات');
        Get.snackbar('خطأ', detailError.value!,
            backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      }
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> purchaseCourse(int courseId) async {
    if (isPurchasing.value || isPurchased(courseId)) return;
    isPurchasing.value = true;
    try {
      await _purchaseProvider.purchaseCourse(courseId);
      purchasedIds.add(courseId);
      HapticFeedback.lightImpact();
      Get.snackbar('نجاح', 'تم شراء الدورة بنجاح',
          backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
      if (Get.isRegistered<NotificationsController>()) {
        unawaited(Get.find<NotificationsController>().refreshUnreadCount());
      }
      loadCourseDetail(courseId, course: currentCourse.value);
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل الشراء'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isPurchasing.value = false;
    }
  }
}
