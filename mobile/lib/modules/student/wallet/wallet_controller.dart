import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/wallet_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/topup_request_model.dart';

class WalletController extends GetxController {
  final WalletProvider _walletProvider;

  WalletController() : _walletProvider = WalletProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final balance = '0.00'.obs;
  final transactions = <TransactionModel>[].obs;
  final topupRequests = <TopupRequestModel>[].obs;
  final totalTopups = '0.00'.obs;
  final totalPurchases = '0.00'.obs;
  final totalDiscounts = '0.00'.obs;

  @override
  void onInit() {
    super.onInit();
    loadWallet();
  }

  Future<void> loadWallet() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _walletProvider.getWallet(),
        _walletProvider.getTransactions(limit: 50),
        _walletProvider.getTopupRequests(limit: 50),
      ]);

      balance.value = (results[0].data['data']?['balance'] ?? '0.00').toString();

      final txData = results[1].data['data'];
      if (txData is List) {
        transactions.value = txData.map<TransactionModel>((e) => TransactionModel.fromJson(e)).toList();

        double topupTotal = 0;
        double purchaseTotal = 0;
        for (final tx in transactions) {
          if (tx.isTopup) topupTotal += double.tryParse(tx.amount) ?? 0;
          if (tx.isPurchase) purchaseTotal += double.tryParse(tx.amount) ?? 0;
        }
        totalTopups.value = topupTotal.toStringAsFixed(2);
        totalPurchases.value = purchaseTotal.toStringAsFixed(2);
      }

      final topupData = results[2].data['data'];
      if (topupData is List) {
        topupRequests.value = topupData.map<TopupRequestModel>((e) => TopupRequestModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل بيانات المحفظة', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(date);
  }
}
