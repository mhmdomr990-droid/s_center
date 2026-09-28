import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  Future<void> delete(Map<String, dynamic> item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('حذف الدورة'),
        content: Text('سيتم حذف "${item['name']}" نهائياً مع محاضراتها. متابعة؟'),
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
      await _provider.deleteCourse(item['id'] as int);
      Get.snackbar('تم', 'تم حذف الدورة', backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshLecturesCourses();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل حذف الدورة', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
