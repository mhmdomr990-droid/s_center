import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/wallet_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/topup_request_model.dart';

class WalletController extends GetxController {
  final WalletProvider _walletProvider;

  WalletController() : _walletProvider = WalletProvider(Get.find<ApiClient>());

  static const int _pageSize = 20;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final balance = '0.00'.obs;
  final transactions = <TransactionModel>[].obs;
  final topupRequests = <TopupRequestModel>[].obs;
  final totalTopups = '0.00'.obs;
  final totalPurchases = '0.00'.obs;
  final totalDiscounts = '0.00'.obs;

  final transactionsTotal = 0.obs;
  final _txOffset = 0.obs;
  final topupTotal = 0.obs;

  bool get hasMoreTransactions => transactions.length < transactionsTotal.value;

  @override
  void onInit() {
    super.onInit();
    loadWallet();
  }

  List<dynamic> _itemsOf(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return const [];
  }

  Future<void> loadWallet() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _walletProvider.getWallet(),
        _walletProvider.getTransactions(limit: _pageSize, offset: 0),
        _walletProvider.getTopupRequests(limit: 50, offset: 0),
      ]);

      balance.value = (results[0].data['data']?['balance'] ?? '0.00').toString();

      final txData = results[1].data['data'];
      transactions.value = _itemsOf(txData).map<TransactionModel>((e) => TransactionModel.fromJson(e)).toList();
      _txOffset.value = transactions.length;
      if (txData is Map) {
        transactionsTotal.value = (txData['total'] as num?)?.toInt() ?? transactions.length;
      } else {
        transactionsTotal.value = transactions.length;
      }
      _recalcTotals();

      final topupData = results[2].data['data'];
      topupRequests.value = _itemsOf(topupData).map<TopupRequestModel>((e) => TopupRequestModel.fromJson(e)).toList();
      if (topupData is Map) {
        topupTotal.value = (topupData['total'] as num?)?.toInt() ?? topupRequests.length;
      } else {
        topupTotal.value = topupRequests.length;
      }
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تحميل بيانات المحفظة'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreTransactions() async {
    if (isLoadingMore.value || !hasMoreTransactions) return;
    isLoadingMore.value = true;
    try {
      final response = await _walletProvider.getTransactions(limit: _pageSize, offset: _txOffset.value);
      final data = response.data['data'];
      final more = _itemsOf(data).map<TransactionModel>((e) => TransactionModel.fromJson(e)).toList();
      transactions.addAll(more);
      _txOffset.value = transactions.length;
      if (data is Map && data['total'] is num) {
        transactionsTotal.value = (data['total'] as num).toInt();
      }
      _recalcTotals();
    } catch (_) {
      // ignore
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _recalcTotals() {
    double topupSum = 0;
    double purchaseSum = 0;
    for (final tx in transactions) {
      if (tx.isTopup) topupSum += double.tryParse(tx.amount) ?? 0;
      if (tx.isPurchase) purchaseSum += double.tryParse(tx.amount) ?? 0;
    }
    totalTopups.value = topupSum.toStringAsFixed(2);
    totalPurchases.value = purchaseSum.toStringAsFixed(2);
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(date);
  }
}
