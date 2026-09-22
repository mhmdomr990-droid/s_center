import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/wallet_provider.dart';
import '../wallet/wallet_controller.dart';

String _normalizeAmountInput(String value) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  var out = value.trim();
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return out.replaceAll('٫', '.').replaceAll('،', '.');
}

class TopupController extends GetxController {
  final WalletProvider _walletProvider;
  final isLoading = false.obs;

  final amountCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();
  final senderCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final selectedMethod = 'SHAM_CASH'.obs;

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
      Get.snackbar('خطأ', 'أدخل جميع البيانات المطلوبة',
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }

    final amount = double.tryParse(_normalizeAmountInput(amountCtrl.text));
    if (amount == null || amount <= 0) {
      Get.snackbar('خطأ', 'أدخل مبلغ صحيح', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
      return;
    }

    isLoading.value = true;
    try {
      await _walletProvider.createTopupRequest(
        amount: amount.toStringAsFixed(2),
        method: selectedMethod.value,
        referenceNumber: referenceCtrl.text.trim(),
        senderName: senderCtrl.text.trim(),
        note: noteCtrl.text.trim(),
      );
      amountCtrl.clear();
      referenceCtrl.clear();
      senderCtrl.clear();
      noteCtrl.clear();
      if (Get.isRegistered<WalletController>()) {
        await Get.find<WalletController>().loadWallet();
      }
      Get.back();
      Get.snackbar('تم الإرسال', 'طلب الشحن قيد المراجعة من الإدارة',
          backgroundColor: Color(0xFF43A047), colorText: Color(0xFFFFFFFF));
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل إرسال الطلب'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
