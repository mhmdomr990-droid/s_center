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

  // منح محاضرات مجانية
  final lectureGrants = <Map<String, dynamic>>[].obs;
  final lectureGrantSheetLoading = false.obs;
  final lectureGrantCourses = <Map<String, dynamic>>[].obs;
  final lectureGrantLectures = <Map<String, dynamic>>[].obs;
  final lectureGrantSelectedCourse = Rxn<Map<String, dynamic>>();
  final lectureGrantSelectedIds = <int>{}.obs;
  final lectureGrantLecturesLoading = false.obs;

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
        await Future.wait([_loadTransactions(), _loadPurchases(), _loadLectureGrants()]);
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

  Future<void> _loadLectureGrants() async {
    try {
      final response = await _provider.userLectureGrants(userId);
      lectureGrants.assignAll(List<Map<String, dynamic>>.from(
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
        content: SingleChildScrollView(
          child: Column(
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

  // ─── منح محاضرات مجانية ───

  Future<void> openLectureGrantSheet() async {
    final u = user.value;
    if (u == null) return;
    final specId = u['specialization_id'];
    if (specId == null) {
      Get.snackbar('منح محاضرة', 'لا يمكن المنح: المستخدم بلا اختصاص',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    lectureGrantSelectedCourse.value = null;
    lectureGrantLectures.clear();
    lectureGrantSelectedIds.clear();
    lectureGrantCourses.clear();
    lectureGrantSheetLoading.value = true;
    _showLectureGrantSheet('${u['full_name'] ?? ''}');

    try {
      await Future.wait([_loadLectureGrants(), _loadPurchases()]);
      final response = await _provider.courses(limit: 100);
      final all = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      lectureGrantCourses.assignAll(all.where((c) =>
          (c['is_published'] ?? true) == true &&
          (c['specialization_id'] as num?)?.toInt() == (specId as num).toInt()));
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل الدورات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      lectureGrantSheetLoading.value = false;
    }
  }

  void _showLectureGrantSheet(String userName) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(Get.context!).size.height * 0.78,
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
                  child: Text('منح محاضرة مجانية — $userName',
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
            Expanded(
              child: Obx(() {
                if (lectureGrantSheetLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  children: [
                    // ── المنح الحالية ──
                    if (lectureGrants.where((g) => (g['revoked'] ?? false) != true).isNotEmpty) ...[
                      Text('المنح الحالية',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      ...lectureGrants
                          .where((g) => (g['revoked'] ?? false) != true)
                          .map(_grantedLectureRow),
                      const SizedBox(height: 12),
                    ],
                    // ── اختيار الكورس ──
                    if (lectureGrantSelectedCourse.value == null) ...[
                      Text('اختر الكورس',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      if (lectureGrantCourses.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('لا توجد دورات منشورة في اختصاص المستخدم',
                              style: AppTextStyles.caption),
                        )
                      else
                        ...lectureGrantCourses.map(_grantCoursePickRow),
                    ] else ...[
                      // ── اختيار المحاضرات ──
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                            color: AppColors.textSecondary,
                            onPressed: lectureGrantLecturesLoading.value
                                ? null
                                : () {
                                    lectureGrantSelectedCourse.value = null;
                                    lectureGrantLectures.clear();
                                    lectureGrantSelectedIds.clear();
                                  },
                          ),
                          Expanded(
                            child: Text('${lectureGrantSelectedCourse.value!['name'] ?? ''}',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (lectureGrantLecturesLoading.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (lectureGrantLectures.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('لا توجد محاضرات منشورة في هذا الكورس',
                              style: AppTextStyles.caption),
                        )
                      else ...[
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                final allIds = lectureGrantLectures
                                    .map((l) => (l['id'] as num).toInt())
                                    .toSet();
                                if (lectureGrantSelectedIds.containsAll(allIds)) {
                                  lectureGrantSelectedIds.clear();
                                } else {
                                  lectureGrantSelectedIds.assignAll(allIds);
                                }
                              },
                              child: Text(
                                lectureGrantSelectedIds.length == lectureGrantLectures.length
                                    ? 'إلغاء تحديد الكل'
                                    : 'تحديد الكل',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            Obx(() => Text(
                                '${lectureGrantSelectedIds.length} محددة',
                                style: AppTextStyles.caption)),
                          ],
                        ),
                        ...lectureGrantLectures.map(_grantLectureCheckboxRow),
                      ],
                    ],
                  ],
                );
              }),
            ),
            // ── زر المنح ──
            Obx(() {
              final selected = lectureGrantSelectedIds.length;
              if (lectureGrantSelectedCourse.value == null || selected == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: busy.value ? null : () => grantSelectedLectures(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.card_giftcard_outlined,
                        color: Colors.white, size: 20),
                    label: Text('منح $selected محاضرة',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _grantedLectureRow(Map<String, dynamic> g) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${g['lecture_title'] ?? ''}',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('${g['course_name'] ?? ''}',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(
              onPressed: busy.value ? null : () => revokeLectureGrant(g),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCourseOwnedByUser(int courseId) =>
      purchases.any((p) => (p['course_id'] as num?)?.toInt() == courseId);

  Widget _grantCoursePickRow(Map<String, dynamic> c) {
    final courseId = (c['id'] as num).toInt();
    final owned = _isCourseOwnedByUser(courseId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: lectureGrantLecturesLoading.value || owned
              ? null
              : () => _selectLectureGrantCourse(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Opacity(
              opacity: owned ? 0.5 : 1,
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${c['name'] ?? ''}',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                  ),
                  if (owned)
                    const Text('مملوكة',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success)),
                  Icon(Icons.chevron_left_rounded,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLectureGrantCourse(Map<String, dynamic> course) async {
    final courseId = (course['id'] as num).toInt();
    if (_isCourseOwnedByUser(courseId)) {
      Get.snackbar('منح محاضرة', 'الطالب يملك هذه الدورة بالكامل',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    lectureGrantSelectedCourse.value = course;
    lectureGrantSelectedIds.clear();
    lectureGrantLectures.clear();
    lectureGrantLecturesLoading.value = true;
    try {
      final response =
          await _provider.lectures(courseId: courseId, limit: 100);
      final all = List<Map<String, dynamic>>.from(
          (response.data['data'] as List).map((e) => Map<String, dynamic>.from(e)));
      // استبعاد المحاضرات الممنوحة مسبقاً (غير الملغاة)
      final grantedIds = lectureGrants
          .where((g) => (g['revoked'] ?? false) != true)
          .map((g) => (g['lecture_id'] as num).toInt())
          .toSet();
      lectureGrantLectures.assignAll(all.where((l) =>
          (l['is_published'] ?? true) == true &&
          !grantedIds.contains((l['id'] as num).toInt())));
    } catch (_) {
      Get.snackbar('خطأ', 'تعذّر تحميل المحاضرات',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      lectureGrantLecturesLoading.value = false;
    }
  }

  Widget _grantLectureCheckboxRow(Map<String, dynamic> l) {
    final id = (l['id'] as num).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Obx(() {
        final checked = lectureGrantSelectedIds.contains(id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (checked) {
                lectureGrantSelectedIds.remove(id);
              } else {
                lectureGrantSelectedIds.add(id);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: checked ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${l['title'] ?? ''}',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${l['type'] ?? ''}', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> grantSelectedLectures() async {
    if (busy.value) return;
    final ids = lectureGrantSelectedIds.toList();
    if (ids.isEmpty) return;
    busy.value = true;
    try {
      final response = await _provider.grantLectures(userId, ids);
      final message = '${response.data['data']?['message'] ?? 'تم منح المحاضرات'}';
      Get.snackbar('تم', message,
          backgroundColor: Colors.green, colorText: Colors.white);
      lectureGrantSelectedIds.clear();
      await _loadLectureGrants();
      // تحديث حالة الشيت: إزالة المحاضرات الممنوحة من القائمة
      lectureGrantLectures.removeWhere(
          (l) => lectureGrants.any((g) => g['lecture_id'] == l['id'] && (g['revoked'] ?? false) != true));
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      Get.snackbar(
          'خطأ',
          status == 409
              ? 'بعض المحاضرات ممنوحة مسبقاً أو الطالب يملك الكورس كاملاً'
              : status == 404
                  ? 'محاضرة غير موجودة أو غير منشورة'
                  : apiErrorMessage(e),
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }

  Future<void> revokeLectureGrant(Map<String, dynamic> grant) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء المنحة'),
        content: Text('هل تريد إلغاء منحة المحاضرة "${grant['lecture_title'] ?? ''}"؟'),
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
      await _provider.revokeLectureGrant(userId, (grant['lecture_id'] as num).toInt());
      Get.snackbar('تم', 'تم إلغاء المنحة',
          backgroundColor: Colors.green, colorText: Colors.white);
      await _loadLectureGrants();
      // إعادة المحاضرة إلى قائمة المنح إن كانت في الكورس المفتوح
      if (lectureGrantSelectedCourse.value != null &&
          lectureGrantSelectedCourse.value!['id'] == grant['course_id']) {
        await _selectLectureGrantCourse(lectureGrantSelectedCourse.value!);
      }
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      Get.snackbar(
          'خطأ',
          status == 404 ? 'المنحة غير موجودة' : apiErrorMessage(e),
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      busy.value = false;
    }
  }
}
