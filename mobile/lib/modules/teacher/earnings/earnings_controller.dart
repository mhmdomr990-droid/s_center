import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/teacher_provider.dart';
import '../../../data/models/payout_model.dart';

class EarningsController extends GetxController {
  final TeacherProvider _teacherProvider;

  EarningsController() : _teacherProvider = TeacherProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final totalEarned = '0.00'.obs;
  final totalPaid = '0.00'.obs;
  final remaining = '0.00'.obs;
  final payouts = <PayoutModel>[].obs;
  final selectedMonth = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedMonth.value = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    loadEarnings();
  }

  Future<void> loadEarnings() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _teacherProvider.getStats(),
        _teacherProvider.getPayouts(),
      ]);

      final stats = results[0].data['data'];
      totalEarned.value = (stats['total_earned'] ?? '0.00').toString();
      totalPaid.value = (stats['total_paid'] ?? '0.00').toString();
      remaining.value = (stats['remaining'] ?? '0.00').toString();

      final payoutData = results[1].data['data'];
      if (payoutData is List) {
        payouts.value = payoutData.map<PayoutModel>((e) => PayoutModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل الأرباح', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
