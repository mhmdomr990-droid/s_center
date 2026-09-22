import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/wallet_provider.dart';
import '../../../data/providers/purchase_provider.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/purchase_model.dart';

class HomeController extends GetxController {
  final CatalogProvider _catalogProvider;
  final WalletProvider _walletProvider;
  final PurchaseProvider _purchaseProvider;

  HomeController()
      : _catalogProvider = CatalogProvider(Get.find<ApiClient>()),
        _walletProvider = WalletProvider(Get.find<ApiClient>()),
        _purchaseProvider = PurchaseProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final balance = '0.00'.obs;
  final myCourses = <PurchaseModel>[].obs;
  final latestCourses = <CourseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _walletProvider.getWallet(),
        _purchaseProvider.getMyCourses(),
        _catalogProvider.getCourses(),
      ]);

      balance.value = (results[0].data['data']?['balance'] ?? '0.00').toString();

      final coursesData = results[1].data['data'];
      if (coursesData is List) {
        myCourses.value = coursesData.map<PurchaseModel>((e) => PurchaseModel.fromJson(e)).toList();
      }

      final catalogData = results[2].data['data'];
      if (catalogData is List) {
        latestCourses.value = catalogData.map<CourseModel>((e) => CourseModel.fromJson(e)).toList().take(5).toList();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل البيانات', backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
