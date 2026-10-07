import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../admin_shell.dart';

class TopupRequestsController extends GetxController {
  final AdminProvider _provider;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final statusFilter = 'PENDING'.obs;
  final items = <Map<String, dynamic>>[].obs;
  final total = 0.obs;

  // 0 = طلبات الشحن، 1 = طلبات التبديل
  final segment = 0.obs;

  void setSegment(int value) {
    if (segment.value == value) return;
    segment.value = value;
  }

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  final rejectReasonCtrl = TextEditingController();

  TopupRequestsController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    rejectReasonCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    _page = 1;
    isLoading.value = true;
    try {
      final response = await _provider.topupRequests(status: statusFilter.value, page: _page);
      final data = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      items.assignAll(data);
      total.value = (response.data['meta']?['total'] ?? data.length) as int;
      _hasMore = data.length < total.value;
    } catch (_) {
      // رسالة الخطأ تظهر عبر(snackbar) عند الإجراءات؛ التحميل الصامت يكفي هنا
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final response =
          await _provider.topupRequests(status: statusFilter.value, page: _page + 1);
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

  Future<void> setStatus(String status) async {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
    await load();
  }

  Future<void> approve(Map<String, dynamic> req) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text(
            'سيُضاف مبلغ ${req['amount']} SYP إلى رصيد المستخدم ${req['full_name']} (${req['username']})؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('موافقة', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    try {
      await _provider.approveTopup(req['id'] as int);
      Get.snackbar('تم', 'تمت موافقة طلب الشحن',
          backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshBadge();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الموافقة على الطلب',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> reject(Map<String, dynamic> req) async {
    rejectReasonCtrl.clear();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('رفض طلب الشحن'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطلب: ${req['amount']} SYP — ${req['full_name']}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: rejectReasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (إلزامي)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('رفض', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    final reason = rejectReasonCtrl.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('خطأ', 'أدخل سبب الرفض', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      await _provider.rejectTopup(req['id'] as int, reason: reason);
      Get.snackbar('تم', 'تم رفض طلب الشحن',
          backgroundColor: Colors.green, colorText: Colors.white);
      await load();
      _refreshBadge();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل رفض الطلب',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _refreshBadge() {
    if (Get.isRegistered<AdminShellController>()) {
      Get.find<AdminShellController>().loadBadges();
    }
  }

  String statusLabel(String status) => switch (status) {
        'APPROVED' => 'مقبول',
        'REJECTED' => 'مرفوض',
        _ => 'معلّق',
      };
}
