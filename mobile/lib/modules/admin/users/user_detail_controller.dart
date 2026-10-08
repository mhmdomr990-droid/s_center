import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../utils/format.dart';

class UserDetailController extends GetxController {
  final AdminProvider _provider;
  final isLoading = true.obs;
  final user = Rxn<Map<String, dynamic>>();
  final transactions = <Map<String, dynamic>>[].obs;
  final purchases = <Map<String, dynamic>>[].obs;
  final teacherPayouts = <Map<String, dynamic>>[].obs;
  final teacherCourses = <Map<String, dynamic>>[].obs;
  final teacherTotals = Rxn<Map<String, dynamic>>();
  final tab = 0.obs; // طالب: 0 = حركات، 1 = مشتريات | معلم: 0 = دفعات، 1 = دورات
  final busy = false.obs;

  final grantSheetLoading = false.obs;
  final grantSearchQuery = ''.obs;
  final grantCourses = <Map<String, dynamic>>[].obs;
  final _ownedCourseIds = <int>{}.obs;
  late final TextEditingController grantSearchCtrl;

  late final int userId;

  final adjustAmountCtrl = TextEditingController();
  final adjustDescCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();

  UserDetailController()
      : _provider = AdminProvider(Get.find<ApiClient>()),
        grantSearchCtrl = TextEditingController();

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
    grantSearchCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    teacherTotals.value = null;
    try {
      final response = await _provider.userById(userId);
      user.value = Map<String, dynamic>.from(response.data['data']);
      if (user.value?['specialization_id'] == null) {
        await _mergeSpecializationFromList();
      }
      final role = (user.value?['role'] ?? 'STUDENT').toString();
      if (role == 'TEACHER') {
        await _loadTeacherData();
      } else {
        await Future.wait([_loadTransactions(), _loadPurchases()]);
      }
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل بيانات المستخدم',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // getUserById في الباك لا يُحمّل relation الاختصاص (تعيد null دائماً) —
  // نسحبه من قائمة المستخدمين التي تعيد الاختصاص بشكل صحيح.
  Future<void> _mergeSpecializationFromList() async {
    try {
      final username = '${user.value?['username'] ?? ''}';
      if (username.isEmpty) return;
      final response = await _provider.users(search: username, limit: 20);
      final rows = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      for (final row in rows) {
        if ((row['id'] as num?)?.toInt() == userId) {
          user.value = {
            ...?user.value,
            'specialization_id': row['specialization_id'],
            'specialization_name': row['specialization_name'],
          };
          return;
        }
      }
    } catch (_) {}
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

  Future<void> _loadTeacherData() async {
    try {
      final response = await _provider.teacherById(userId);
      final data = Map<String, dynamic>.from(response.data['data']);
      final totals = data['totals'];
      teacherTotals.value =
          totals == null ? null : Map<String, dynamic>.from(totals);
      teacherPayouts.assignAll(List<Map<String, dynamic>>.from(
          ((data['payouts'] ?? []) as List).map((e) => Map<String, dynamic>.from(e))));
      teacherCourses.assignAll(List<Map<String, dynamic>>.from(
          ((data['courses'] ?? []) as List).map((e) => Map<String, dynamic>.from(e))));
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

  // ─── منح كورس مجاني ───

  List<Map<String, dynamic>> get grantableCourses {
    final q = grantSearchQuery.value.toLowerCase();
    return grantCourses.where((c) {
      if (q.isEmpty) return true;
      return '${c['name']}'.toLowerCase().contains(q);
    }).toList();
  }

  void onGrantSearchChanged(String value) {
    grantSearchQuery.value = value.trim().toLowerCase();
  }

  String _grantError(Object e) {
    final status = e is DioException ? e.response?.statusCode : null;
    switch (status) {
      case 400:
        return 'الدورة لا تطابق اختصاص المستخدم';
      case 404:
        return 'الدورة غير منشورة أو غير موجودة';
      case 409:
        return 'المستخدم لديه وصول لهذه الدورة';
      default:
        return apiErrorMessage(e);
    }
  }

  Future<void> openGrantSheet() async {
    final u = user.value;
    if (u == null) return;
    final specId = u['specialization_id'];
    if (specId == null) {
      Get.snackbar('منح كورس', 'لا يمكن المنح: المستخدم بلا اختصاص',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    grantSearchCtrl.clear();
    grantSearchQuery.value = '';
    grantCourses.clear();
    _ownedCourseIds
      ..clear()
      ..addAll(purchases.map((p) => (p['course_id'] as num).toInt()));
    grantSheetLoading.value = true;
    _showGrantSheet('${u['full_name'] ?? ''}');

    try {
      final response = await _provider.courses(limit: 100);
      final all = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      grantCourses.assignAll(all.where((c) =>
          (c['is_published'] ?? true) == true &&
          (c['specialization_id'] as num?)?.toInt() == (specId as num).toInt()));
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل الدورات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      grantSheetLoading.value = false;
    }
  }

  void _showGrantSheet(String userName) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(Get.context!).size.height * 0.72,
        decoration: BoxDecoration(
          color: AppColors.courseCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('منح كورس مجاني — $userName',
                      style: AppTextStyles.titleMedium),
                ),
                Obx(() => busy.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary))
                    : const SizedBox.shrink()),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            CustomTextField(
              labelText: 'بحث في دورات الاختصاص',
              prefixIcon: Icons.search_rounded,
              controller: grantSearchCtrl,
              onChanged: onGrantSearchChanged,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (grantSheetLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = grantableCourses;
                if (list.isEmpty) {
                  return Center(
                    child: Text('لا توجد دورات منشورة في اختصاص المستخدم',
                        style: AppTextStyles.caption),
                  );
                }
                final years = <int>{
                  for (final c in list) ((c['year'] as num?)?.toInt() ?? 0)
                }.toList()
                  ..sort();
                return ListView(
                  children: [
                    for (final year in years) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          _yearLabel(year),
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                      ..._yearCourses(list, year),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> grantCourse(int courseId) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _provider.grantCourse(userId, courseId);
      _ownedCourseIds.add(courseId);
      Get.snackbar('تم', 'تمت المنحة المجانية للطالب',
          backgroundColor: Colors.green, colorText: Colors.white);
      await load();
    } catch (e) {
      Get.snackbar('خطأ', _grantError(e),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  String _yearLabel(int year) => switch (year) {
        1 => 'السنة الأولى',
        2 => 'السنة الثانية',
        3 => 'السنة الثالثة',
        4 => 'السنة الرابعة',
        5 => 'السنة الخامسة',
        _ => 'سنة $year',
      };

  List<Widget> _yearCourses(List<Map<String, dynamic>> list, int year) {
    final rows = list
        .where((c) => ((c['year'] as num?)?.toInt() ?? 0) == year)
        .toList()
      ..sort((a, b) => '${a['name'] ?? ''}'.compareTo('${b['name'] ?? ''}'));
    return rows.map(_grantCourseRow).toList();
  }

  Widget _grantCourseRow(Map<String, dynamic> c) {
    final owned = _ownedCourseIds.contains((c['id'] as num).toInt());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: owned
            ? AppColors.background.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: owned || busy.value
              ? null
              : () => grantCourse((c['id'] as num).toInt()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.play_lesson_outlined,
                    color: owned ? AppColors.textHint : AppColors.primary,
                    size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c['name'] ?? ''}',
                          style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14,
                              color: owned ? AppColors.textHint : null),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('${formatAmount(c['price'])} SYP',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (owned)
                  const Text('مُتاح',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))
                else ...[
                  Text('منح',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle_outline,
                      color: AppColors.primary, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> revokeGrant(int courseId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء المنحة'),
        content: const Text('هل تريد إلغاء هذه المنحة المجانية؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('تراجع')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('إلغاء المنحة', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    busy.value = true;
    try {
      await _provider.revokeCourseGrant(userId, courseId);
      Get.snackbar('تم', 'تم إلغاء المنحة',
          backgroundColor: Colors.green, colorText: Colors.white);
      await load();
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      Get.snackbar(
          'خطأ',
          status == 404
              ? 'ليست منحة مجانية — ربما شراء مدفوع'
              : apiErrorMessage(e),
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
