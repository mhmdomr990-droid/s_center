import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/wallet_provider.dart';
import '../../../data/providers/purchase_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/auth_controller.dart';

class HomeController extends GetxController {
  final CatalogProvider _catalogProvider;
  final WalletProvider _walletProvider;
  final PurchaseProvider _purchaseProvider;
  final StorageService _storage;

  HomeController()
      : _catalogProvider = CatalogProvider(Get.find<ApiClient>()),
        _walletProvider = WalletProvider(Get.find<ApiClient>()),
        _purchaseProvider = PurchaseProvider(Get.find<ApiClient>()),
        _storage = Get.find<StorageService>();

  final isLoading = true.obs;
  final balance = '0.00'.obs;
  final userName = ''.obs;
  final myCourses = <PurchaseModel>[].obs;
  final latestCourses = <CourseModel>[].obs;

  /// هل اختار الطالب اختصاصاً عند التسجيل؟ (رسالة لمن بلا اختصاص)
  bool get hasSpecialization => Get.isRegistered<AuthController>()
      ? Get.find<AuthController>().user.value?.specializationId != null
      : false;

  Map<int, String> _specNames = {};

  @override
  void onInit() {
    super.onInit();
    _syncUserName();
    loadData();
  }

  // الاسم يُقرأ من AuthController ويتحدث رياضياً فور تعديل الاسم من الملف
  // الشخصي (ever() يتوقف تلقائياً مع دورة حياة المتحكّم — لا تسريب)
  void _syncUserName() {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      userName.value = _nameOf(auth.user.value);
      ever(auth.user, (u) => userName.value = _nameOf(u));
    } else {
      // احتياط: قراءة من التخزين إن لم يكن AuthController مسجّلاً
      _loadUserName();
    }
  }

  String _nameOf(UserModel? user) => user != null && user.fullName.isNotEmpty
      ? user.fullName
      : (user?.username ?? '');

  Future<void> _loadUserName() async {
    final user = await _storage.getUser();
    userName.value = _nameOf(user);
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _walletProvider.getWallet(),
        _purchaseProvider.getMyCourses(),
        _catalogProvider.getCourses(),
        _catalogProvider.getSpecializations(),
      ]);

      balance.value = (results[0].data['data']?['balance'] ?? '0.00').toString();

      final specData = results[3].data['data'];
      if (specData is List) {
        _specNames = {
          for (final e in specData)
            (e['id'] as num?)?.toInt() ?? 0: (e['name'] ?? '').toString()
        };
      }

      final coursesData = results[1].data['data'];
      if (coursesData is List) {
        myCourses.value = coursesData.map<PurchaseModel>((e) {
          final purchase = PurchaseModel.fromJson(e);
          final specName = _specNames[purchase.specializationId];
          if (purchase.specializationName == null &&
              specName != null &&
              specName.isNotEmpty) {
            return purchase.withSpecializationName(specName);
          }
          return purchase;
        }).toList();
      }

      final catalogData = results[2].data['data'];
      if (catalogData is List) {
        // واجهة الطالب تعرض تخصصه فقط — فل أمان جانب العميل
        final mySpecId = Get.isRegistered<AuthController>()
            ? Get.find<AuthController>().user.value?.specializationId
            : null;
        final parsed = catalogData.map<CourseModel>((e) {
          final json = Map<String, dynamic>.from(e as Map);
          if ((json['specialization_name'] == null ||
                  json['specialization_name'] == '') &&
              _specNames.containsKey(json['specialization_id'])) {
            json['specialization_name'] = _specNames[json['specialization_id']];
          }
          return CourseModel.fromJson(json);
        });
        latestCourses.value = (mySpecId == null
                ? <CourseModel>[]
                : parsed.where((c) => c.specializationId == mySpecId))
            .take(5)
            .toList();
      }

    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'فشل تحميل البيانات'),
          backgroundColor: Color(0xFFE53935), colorText: Color(0xFFFFFFFF));
    } finally {
      isLoading.value = false;
    }
  }
}
