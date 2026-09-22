import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/wallet_provider.dart';

class TopupController extends GetxController {
  final WalletProvider _walletProvider;
  final isLoading = false.obs;

  final amountCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();
  final senderCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final selectedMethod = 'sham_cash'.obs;

  TopupController() : _walletProvider = WalletProvider(Get.find<ApiClient>());

  @override
  void onClose() {
    amountCtrl.dispose();
    referenceCtrl.dispose();
    senderCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }

  Future<void> submitTopup() async {
    if (amountCtrl.text.isEmpty || referenceCtrl.text.isEmpty || senderCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'أدخل جميع البيانات المطلوبة', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }

    final amount = double.tryParse(amountCtrl.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('خطأ', 'أدخل مبلغ صحيح', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }

    isLoading.value = true;
    try {
      await _walletProvider.createTopupRequest(
        amount: amountCtrl.text,
        method: selectedMethod.value,
        referenceNumber: referenceCtrl.text.trim(),
        senderName: senderCtrl.text.trim(),
        note: noteCtrl.text.trim(),
      );
      Get.back();
      Get.snackbar('نجاح', 'تم إرسال طلب الشحن بنجاح', backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
    } catch (e) {
      String msg = 'فشل إرسال الطلب';
      if (e.toString().contains('already submitted')) msg = 'هذا التحويل مُرسل بالفعل';
      Get.snackbar('خطأ', msg, backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
