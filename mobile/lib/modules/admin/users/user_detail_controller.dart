import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';

class UserDetailController extends GetxController {
  final AdminProvider _provider;
  final isLoading = true.obs;
  final user = Rxn<Map<String, dynamic>>();
  final transactions = <Map<String, dynamic>>[].obs;
  final purchases = <Map<String, dynamic>>[].obs;
  final tab = 0.obs; // 0 = حركات، 1 = مشتريات
  final busy = false.obs;

  late final int userId;

  final adjustAmountCtrl = TextEditingController();
  final adjustDescCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();

  UserDetailController() : _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    userId = (Get.arguments as Map)['userId'] as int;
    load();
  }

  @override
  void onClose() {
    adjustAmountCtrl.dispose();
    adjustDescCtrl.dispose();
    newPasswordCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final response = await _provider.userById(userId);
      user.value = Map<String, dynamic>.from(response.data['data']);
      await Future.wait([_loadTransactions(), _loadPurchases()]);
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل بيانات المستخدم',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final response = await _provider.userTransactions(userId);
      transactions.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {}
  }

  Future<void> _loadPurchases() async {
    try {
      final response = await _provider.userPurchases(userId);
      purchases.assignAll(List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e))));
    } catch (_) {}
  }

  Future<void> toggleActive() async {
    final u = user.value;
    if (u == null) return;
    final next = !(u['is_active'] ?? true);
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(next ? 'تفعيل الحساب' : 'تعطيل الحساب'),
        content: Text(next
            ? 'سيتم تفعيل حساب ${u['full_name']}؟'
            : 'سيتم تعطيل حساب ${u['full_name']} ولن يستطيع الدخول.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(next ? 'تفعيل' : 'تعطيل'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    await _run(() => _provider.setUserActive(userId, isActive: next),
        success: next ? 'تم تفعيل الحساب' : 'تم تعطيل الحساب');
  }

  Future<void> resetDevice() async {
    final u = user.value;
    if (u == null) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إعادة تعيين الجهاز'),
        content: Text(
            'سيتم فصل ${u['full_name']} عن جهازه الحالي وسيتمكن من الدخول من جهاز آخر. متابعة؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('إعادة تعيين', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    await _run(() => _provider.resetUserDevice(userId), success: 'تمت إعادة تعيين الجهاز');
  }

  Future<void> adjustBalance() async {
    adjustAmountCtrl.clear();
    adjustDescCtrl.clear();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تسوية الرصيد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adjustAmountCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ (سالب للخصم)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adjustDescCtrl,
              decoration: const InputDecoration(
                labelText: 'الوصف (إلزامي)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('تطبيق')),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    final amount = adjustAmountCtrl.text.trim();
    final desc = adjustDescCtrl.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null || desc.isEmpty) {
      Get.snackbar('خطأ', 'أدخل مبلغاً صحيحاً ووصفاً',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    await _run(() => _provider.adjustBalance(userId, amount: amount, description: desc),
        success: 'تمت تسوية الرصيد');
  }

  Future<void> resetPassword() async {
    newPasswordCtrl.clear();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إعادة تعيين كلمة المرور'),
        content: TextField(
          controller: newPasswordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور الجديدة (8 أحرف على الأقل)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('تعيين')),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    final password = newPasswordCtrl.text;
    if (password.length < 8) {
      Get.snackbar('خطأ', 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    await _run(() => _provider.resetPassword(userId, newPassword: password),
        success: 'تم تغيير كلمة المرور');
  }

  Future<void> _run(Future<dynamic> Function() action, {required String success}) async {
    busy.value = true;
    try {
      await action();
      Get.snackbar('تم', success, backgroundColor: Colors.green, colorText: Colors.white);
      await load();
    } catch (_) {
      Get.snackbar('خطأ', 'فشل تنفيذ العملية — تحقق من الصلاحيات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
