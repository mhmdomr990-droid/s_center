import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../app/routes/app_routes.dart';

class UsersController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final items = <Map<String, dynamic>>[].obs;
  final total = 0.obs;
  final roleFilter = ''.obs;
  final searchQuery = ''.obs;

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

  String roleLabel(String role) => switch (role) {
        'ADMIN' => 'إداري',
        'TEACHER' => 'معلم',
        _ => 'طالب',
      };
}
