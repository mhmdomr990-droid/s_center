import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import 'lectures_controller.dart';

class CoursesController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final busy = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final total = 0.obs;
  final specializations = <Map<String, dynamic>>[].obs;
  final teachers = <Map<String, dynamic>>[].obs;
  final selectedSpecId = RxnInt();
  final selectedYear = RxnInt();
  final searchQuery = ''.obs;

  final searchCtrl = TextEditingController();
  Timer? _debounce;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  CoursesController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    loadMeta();
    load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> loadMeta() async {
    try {
      final specResponse = await _provider.specializations();
      final specs = List<Map<String, dynamic>>.from(
          (specResponse.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      specializations.assignAll(specs);
      final selected = selectedSpecId.value;
      if (selected != null && !specs.any((s) => s['id'] == selected)) {
        selectedSpecId.value = null;
        load();
      }
    } catch (_) {}
    try {
      final teacherResponse = await _provider.teachers();
      teachers.assignAll(List<Map<String, dynamic>>.from(
          (teacherResponse.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {}
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      searchQuery.value = value.trim();
      load();
    });
  }

  Future<void> load() async {
    _page = 1;
    isLoading.value = true;
    try {
      final response = await _provider.courses(
        specializationId: selectedSpecId.value,
        year: selectedYear.value,
        search: searchQuery.value,
        page: _page,
      );
      final data = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      items.assignAll(data);
      total.value = (response.data['meta']?['total'] ?? data.length) as int;
      _hasMore = data.length < total.value;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final response = await _provider.courses(
        specializationId: selectedSpecId.value,
        year: selectedYear.value,
        search: searchQuery.value,
        page: _page + 1,
      );
      final data = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      if (data.isEmpty) {
        _hasMore = false;
      } else {
        _page++;
        items.addAll(data);
        _hasMore = items.length < total.value;
      }
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _refreshLecturesCourses() {
    if (Get.isRegistered<LecturesController>()) {
      Get.find<LecturesController>().loadCourses();
    }
  }

  Future<void> createCourse(Map<String, dynamic> body) async {
    busy.value = true;
    try {
      await _provider.createCourse(body);
      Get.snackbar('تم', 'تم إنشاء الدورة', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshLecturesCourses();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل إنشاء الدورة — تحقق من البيانات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> updateCourse(int id, Map<String, dynamic> body) async {
    busy.value = true;
    try {
      await _provider.updateCourse(id, body);
      Get.snackbar('تم', 'تم تحديث الدورة', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshLecturesCourses();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تحديث الدورة', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> togglePublished(Map<String, dynamic> item) async {
    busy.value = true;
    try {
      await _provider.setCoursePublished(
          item['id'] as int, isPublished: !(item['is_published'] ?? true));
      await load();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تغيير حالة النشر', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  // ── مشترو الدورة ──
  final purchasersLoading = false.obs;
  final purchasers = <Map<String, dynamic>>[].obs;

  Future<void> openPurchasersSheet(Map<String, dynamic> course) async {
    final courseId = (course['id'] as num).toInt();
    final courseName = '${course['name'] ?? ''}';
    purchasers.clear();
    purchasersLoading.value = true;
    _showPurchasersSheet(courseName);
    try {
      final response =
          await _provider.purchaseHistory(courseName: courseName, limit: 100);
      final all = List<Map<String, dynamic>>.from((response.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e)));
      // فلترة بمطابقة course_id الدقيقة (فلتر الباك LIKE قد يشمل كورسات مشابهة)
      purchasers.assignAll(all
          .where((p) => (p['course_id'] as num?)?.toInt() == courseId));
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل قائمة المشترين',
          backgroundColor: Colors.red, colorText: Colors.white);
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
            if (date.isNotEmpty)
              Text(date, style: AppTextStyles.caption),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    color:
                        granted ? AppColors.success : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
