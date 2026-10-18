import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/teacher_provider.dart';
import '../../../data/services/catalog_lookup.dart';
import '../../../data/services/upload_manager.dart';
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
        // اختصاص غير معروف (0): يطابق أي فلتر — دورات المعلم لا تختفي
        // عن صاحبها (تُعرف من الكتالوج أو الكاش بعد أول نشر)
        final specOk = selectedSpecializationId.value == null ||
            course.specializationId <= 0 ||
            course.specializationId == selectedSpecializationId.value;
        final yearOk =
            selectedYear.value == null || course.year == selectedYear.value;
        return specOk && yearOk;
      }).toList();

  /// رقائق الاختصاصات: من اختصاصات دوراتي فعلياً (+ المختار لو فقد دوراته)
  List<SpecializationModel> get chipSpecializations {
    final ids =
        courses.map((c) => c.specializationId).where((id) => id > 0).toSet();
    final list =
        specializations.where((s) => ids.contains(s.id)).toList(growable: true);
    final selected = selectedSpecializationId.value;
    if (selected != null && !list.any((s) => s.id == selected)) {
      final sel = specializations.firstWhereOrNull((s) => s.id == selected);
      if (sel != null) list.insert(0, sel);
    }
    return list;
  }

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

  static const String _specCacheKey = 'teacher_course_spec_v1';

  /// خريطة دورة ← اختصاص من مصدرين: الكتالوج لكل اختصاص على حدة
  /// (مسار الكتالوج بلا فلتر محصور باختصاص المستخدم نفسه) + الكاش المحلي
  Future<Map<int, int>> _buildSpecMap() async {
    final map = <int, int>{};
    try {
      final raw =
          (await SharedPreferences.getInstance()).getString(_specCacheKey);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
          final id = int.tryParse(k);
          if (id != null) map[id] = (v as num).toInt();
        });
      }
    } catch (_) {}
    try {
      final perSpec = await Future.wait(specializations
          .map((s) => _catalogProvider.getCourses(specializationId: s.id)));
      for (var i = 0; i < perSpec.length; i++) {
        final list = perSpec[i].data['data'];
        if (list is List) {
          for (final e in list) {
            final id = ((e as Map)['id'] as num?)?.toInt();
            if (id != null && id > 0) map[id] = specializations[i].id;
          }
        }
      }
    } catch (_) {
      // إثراء اختياري — يبقى الكاش والإثراء الأساسي كافيين
    }
    return map;
  }

  /// حفظ كل اختصاص معروف محلياً — يبقى صحيحاً حتى بعد إخفاء الدورة
  Future<void> _persistSpecCache(List<CourseModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_specCacheKey);
      final map = <String, int>{};
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
          map[k] = (v as num).toInt();
        });
      }
      var changed = false;
      for (final c in list) {
        if (c.specializationId > 0 && map['${c.id}'] != c.specializationId) {
          map['${c.id}'] = c.specializationId;
          changed = true;
        }
      }
      if (changed) await prefs.setString(_specCacheKey, jsonEncode(map));
    } catch (_) {}
  }

  String _specNameOf(int id) {
    final n = CatalogLookup.specName(id);
    if (n.isNotEmpty) return n;
    return specializations.firstWhereOrNull((s) => s.id == id)?.name ?? '';
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

      final specByCourse = await _buildSpecMap();

      final data = results[0].data['data'];
      if (data is List) {
        courses.value = data.map<CourseModel>((e) {
          final json = Map<String, dynamic>.from(e as Map);
          final enriched = CatalogLookup.enrichJson(json);
          final id =
              ((enriched['id'] ?? enriched['course_id']) as num?)?.toInt() ?? 0;
          var specId = ((enriched['specialization_id'] as num?) ?? 0).toInt();
          if (specId <= 0) {
            final mapped = specByCourse[id];
            if (mapped != null && mapped > 0) {
              specId = mapped;
              enriched['specialization_id'] = mapped;
            }
          }
          if (specId > 0 &&
              '${enriched['specialization_name'] ?? ''}'.isEmpty) {
            enriched['specialization_name'] = _specNameOf(specId);
          }
          return CourseModel.fromJson(enriched);
        }).toList();
        unawaited(_persistSpecCache(courses));
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

  Future<bool> createLecture(int courseId,
      {required String title, required String type, String? url, String? content, int? sortOrder, String? videoFilePath, Uint8List? fileBytes, String? fileName, bool compress = true}) async {
    isSaving.value = true;
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
            videoFilePath != null ? 'تم رفع الملف بنجاح ✓' : 'تم إضافة المحاضرة',
        failMessage: videoFilePath != null ? 'فشل رفع الملف' : 'فشل إضافة المحاضرة',
      ));
      if (ok) {
        _refreshCourseAfterUpload(courseId);
      }
      return ok;
    } finally {
      isSaving.value = false;
    }
  }

  /// تحديث بعد اكتمال رفع — على مُسجَّل حيّ فقط
  /// (مُثبَّت الصفحة المنغلقة فُكَّك ولا يُستدعى عليه)
  void _refreshCourseAfterUpload(int courseId) {
    try {
      if (Get.isRegistered<TeacherCoursesController>()) {
        Get.find<TeacherCoursesController>().loadCourseDetail(courseId);
      }
    } catch (_) {}
  }

  Future<bool> updateLecture(int lectureId, int courseId,
      {required String title, required String type, String? url, String? content, int? sortOrder, String? videoFilePath, Uint8List? fileBytes, String? fileName, bool compress = true}) async {
    isSaving.value = true;
    try {
      final ok = await Get.find<UploadManager>().run(UploadTask(
        isEdit: true,
        lectureId: lectureId,
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
            videoFilePath != null ? 'تم رفع الملف بنجاح ✓' : 'تم تحديث المحاضرة',
        failMessage: videoFilePath != null ? 'فشل رفع الملف' : 'فشل تحديث المحاضرة',
      ));
      if (ok) {
        _refreshCourseAfterUpload(courseId);
      }
      return ok;
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

  // ── مشتري الدورة ──
  final purchasersLoading = false.obs;
  final purchasers = <Map<String, dynamic>>[].obs;

  Future<void> openPurchasersSheet(CourseModel course) async {
    purchasers.clear();
    purchasersLoading.value = true;
    _showPurchasersSheet(course.name);
    try {
      final response = await _teacherProvider.coursePurchasers(course.id);
      final data = response.data['data'];
      if (data is List) {
        purchasers.assignAll(
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل قائمة المشترين',
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF));
    } finally {
      purchasersLoading.value = false;
    }
  }

  void _showPurchasersSheet(String courseName) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(Get.context!).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.courseCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('مشترو الدورة — $courseName',
                      style: AppTextStyles.titleMedium, maxLines: 1),
                ),
                Obx(() => Text('${purchasers.length} طالب',
                    style: AppTextStyles.caption)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(() {
                if (purchasersLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (purchasers.isEmpty) {
                  return Center(
                      child: Text('لا يوجد مشترون بعد',
                          style: AppTextStyles.caption));
                }
                return ListView.builder(
                  itemCount: purchasers.length,
                  itemBuilder: (_, i) => _purchaserRow(i, purchasers[i]),
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _purchaserRow(int index, Map<String, dynamic> p) {
    final granted = '${p['source'] ?? ''}' == 'GRANTED';
    final rawDate = '${p['created_at'] ?? ''}';
    String date = '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      date =
          '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text('${index + 1}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p['full_name'] ?? ''}',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('@${p['username'] ?? ''}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (date.isNotEmpty) Text(date, style: AppTextStyles.caption),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (granted ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                granted ? 'ممنوحة' : 'مُشترى',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: granted ? AppColors.success : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
