import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';

class PurchasesAdminController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final loadedUsers = 0.obs;
  final totalUsers = 0.obs;
  final items = <Map<String, dynamic>>[].obs;
  final typeFilter = ''.obs;
  final searchQuery = ''.obs;
  final searchCtrl = TextEditingController();
  Timer? _debounce;

  PurchasesAdminController() : _provider = AdminProvider(Get.find<ApiClient>());

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
    });
  }

  void setType(String type) {
    typeFilter.value = type;
  }

  bool isFree(Map<String, dynamic> p) => double.tryParse('${p['price_paid']}') == 0;

  bool get hasActiveFilter => searchQuery.value.isNotEmpty || typeFilter.value.isNotEmpty;

  List<Map<String, dynamic>> get filteredItems {
    final q = searchQuery.value.toLowerCase();
    final type = typeFilter.value;
    return items.where((p) {
      final free = isFree(p);
      if (type == 'FREE' && !free) return false;
      if (type == 'PURCHASED' && free) return false;
      if (q.isEmpty) return true;
      return '${p['full_name']}'.toLowerCase().contains(q) ||
          '${p['username']}'.toLowerCase().contains(q) ||
          '${p['course_name']}'.toLowerCase().contains(q) ||
          '${p['specialization_name']}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> load() async {
    isLoading.value = true;
    loadedUsers.value = 0;
    totalUsers.value = 0;
    items.clear();
    try {
      final users = <Map<String, dynamic>>[];
      var page = 1;
      var total = -1;
      while (total < 0 || users.length < total) {
        final response = await _provider.users(page: page, limit: 100);
        final data = List<Map<String, dynamic>>.from(
            (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
        if (data.isEmpty) break;
        users.addAll(data);
        total = (response.data['meta']?['total'] ?? users.length) as int;
        if (data.length < 100) break;
        page++;
        if (page > 100) break;
      }

      totalUsers.value = users.length;
      const chunkSize = 10;
      for (var i = 0; i < users.length; i += chunkSize) {
        final end = i + chunkSize > users.length ? users.length : i + chunkSize;
        final chunk = users.sublist(i, end);
        final results = await Future.wait(chunk.map((u) async {
          try {
            final response = await _provider.userPurchases(u['id'] as int);
            final rows = List<Map<String, dynamic>>.from(
                (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
            return rows
                .map((row) => <String, dynamic>{
                      ...row,
                      'full_name': u['full_name'] ?? '',
                      'username': u['username'] ?? '',
                    })
                .toList();
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }));
        items.addAll(results.expand((r) => r));
        loadedUsers.value = end;
      }
      items.sort(
          (a, b) => '${b['created_at'] ?? ''}'.compareTo('${a['created_at'] ?? ''}'));
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
