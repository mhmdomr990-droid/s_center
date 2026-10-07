import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../app/routes/app_routes.dart';

class UsersController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final busy = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final total = 0.obs;
  final roleFilter = ''.obs;
  final searchQuery = ''.obs;
  final specializations = <Map<String, dynamic>>[].obs;

  final searchCtrl = TextEditingController();
  Timer? _debounce;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  UsersController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    load();
    unawaited(loadSpecializations());
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
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
      final response = await _provider.users(
        search: searchQuery.value,
        role: roleFilter.value,
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
      final response = await _provider.users(
        search: searchQuery.value,
        role: roleFilter.value,
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

  Future<void> setRole(String role) async {
    if (roleFilter.value == role) return;
    roleFilter.value = role;
    await load();
  }

  void openDetail(int userId) {
    Get.toNamed(AppRoutes.adminUserDetail, arguments: {'userId': userId});
  }

  Future<void> loadSpecializations() async {
    try {
      final response = await _provider.specializations(page: 1, limit: 100);
      final data = response.data['data'];
      if (data is List) {
        specializations.value = data
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
      // صامت — الحوار يعيد المحاولة عند الفتح
    }
  }

  Future<void> createStudent({
    required String username,
    required String fullName,
    required String password,
    String? phone,
    required int specializationId,
  }) async {
    if (busy.value) return;
    busy.value = true;
    try {
      final error = await _provider.createStudent(
        username: username,
        fullName: fullName,
        password: password,
        phone: phone,
        specializationId: specializationId,
      );
      if (error != null) {
        Get.snackbar('خطأ', error,
            backgroundColor: const Color(0xFFE53935), colorText: Colors.white);
        return;
      }
      Get.snackbar('نجاح', 'تم إنشاء حساب الطالب',
          backgroundColor: const Color(0xFF43A047), colorText: Colors.white);
      await load();
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'تعذر إنشاء الطالب'),
          backgroundColor: const Color(0xFFE53935), colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  String roleLabel(String role) => switch (role) {
        'ADMIN' => 'إداري',
        'TEACHER' => 'معلم',
        _ => 'طالب',
      };
}
