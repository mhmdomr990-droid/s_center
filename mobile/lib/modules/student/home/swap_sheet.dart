import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/purchase_provider.dart';
import '../../auth/auth_controller.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

// نافذة تبديل المادة (مطابقة لسلوك الويب): المواد البديلة من نفس الاختصاص
// + سبب اختياري ⇐ POST /course-swap-requests
class SwapCourseSheet extends StatefulWidget {
  final PurchaseModel course;
  final Set<int> ownedCourseIds;

  const SwapCourseSheet({
    super.key,
    required this.course,
    required this.ownedCourseIds,
  });

  static Future<void> show(
    PurchaseModel course, {
    required Set<int> ownedCourseIds,
  }) {
    return Get.bottomSheet(
      SwapCourseSheet(
        course: course,
        ownedCourseIds: ownedCourseIds,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<SwapCourseSheet> createState() => _SwapCourseSheetState();
}

class _SwapCourseSheetState extends State<SwapCourseSheet> {
  final CatalogProvider _catalog = CatalogProvider(Get.find<ApiClient>());
  final PurchaseProvider _purchases = PurchaseProvider(Get.find<ApiClient>());

  final _reasonCtrl = TextEditingController();
  List<Map<String, dynamic>> _alternatives = [];
  int? _selectedId;
  bool _loading = true;
  bool _submitting = false;
  bool _allOwned = false;

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlternatives() async {
    final specId = widget.course.specializationId;
    if (specId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await _catalog.getCourses(specializationId: specId);
      final data = res.data['data'];
      if (data is List) {
        final raw = data
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _alternatives = raw
            .where((c) =>
                (c['id'] as num?)?.toInt() != widget.course.courseId &&
                !widget.ownedCourseIds.contains((c['id'] as num?)?.toInt()))
            .toList();
        _allOwned = raw.isNotEmpty && _alternatives.isEmpty;
      }
    } catch (_) {
      // الرسالة تظهر عند الإرسال إن فشل التحميل
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_alternatives.isNotEmpty) _selectedId = _alternatives.first['id'] as int?;
        });
      }
    }
  }

  // تحويل مبلغ نصي (مثل "2500.00") إلى سنتات BigInt — لا double (قاعدة النقود)
  static BigInt _toCents(String value) {
    final v = value.trim();
    final dot = v.indexOf('.');
    final intPart = (dot == -1 ? v : v.substring(0, dot)).trim();
    final fracPart = dot == -1 ? '00' : (v.substring(dot + 1) + '00').substring(0, 2);
    return BigInt.parse(intPart.isEmpty ? '0' : intPart) * BigInt.from(100) +
        BigInt.parse(fracPart.isEmpty ? '00' : fracPart);
  }

  static String _centsToMoney(BigInt cents) {
    final negative = cents < BigInt.zero;
    final abs = negative ? -cents : cents;
    final s = abs.toString().padLeft(3, '0');
    return '${negative ? '-' : ''}${s.substring(0, s.length - 2)}.${s.substring(s.length - 2)}';
  }

  BigInt get _balanceCents =>
      _toCents(Get.find<AuthController>().user.value?.balance ?? '0.00');

  // الفرق الموجب فقط: سعر المادة البديلة − ما دفعه الطالب فعلياً
  // (مطابق لحساب الخادم: نفس القيمة يخصمها/approveCourseSwapRequest عند الفارق الأعلى)
  BigInt get _deltaCents {
    final selected = _alternatives.cast<Map<String, dynamic>?>().firstWhere(
        (c) => (c?['id'] as num?)?.toInt() == _selectedId,
        orElse: () => null);
    if (selected == null) return BigInt.zero;
    final delta = _toCents('${selected['price'] ?? '0.00'}') -
        _toCents(widget.course.pricePaid);
    return delta > BigInt.zero ? delta : BigInt.zero;
  }

  bool get _insufficientBalance => _deltaCents > _balanceCents;

  Future<void> _submit() async {
    if (_selectedId == null) {
      Get.snackbar('تبديل المادة', 'اختر المادة البديلة أولاً',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (_insufficientBalance) {
      Get.snackbar('تبديل المادة', 'رصيدك لا يكفي لهذا التبديل — فرق السعر ${_centsToMoney(_deltaCents)} SYP ورصيدك ${_centsToMoney(_balanceCents)} SYP',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    final purchaseId = widget.course.purchaseId;
    if (purchaseId == null) {
      Get.snackbar('تبديل المادة', 'تعذر تحديد عملية الشراء لهذه الدورة',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => _submitting = true);
    try {
      await _purchases.requestSwap(
        oldPurchaseId: purchaseId,
        newCourseId: _selectedId!,
        reason: _reasonCtrl.text.trim(),
      );
      Get.back();
      Get.snackbar('تم', 'تم إرسال طلب تبديل المادة. بانتظار موافقة الإدارة',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', apiErrorMessage(e, fallback: 'تعذر إرسال طلب التبديل'),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تبديل المادة',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('من: ${widget.course.courseName}',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_alternatives.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  widget.course.specializationId == null
                      ? 'لا يمكن التبديل: لا يوجد اختصاص مرتبط بالدورة'
                      : _allOwned
                          ? 'لا توجد مواد بديلة — تملك مواد اختصاصك كلها'
                          : 'لا توجد مواد بديلة متاحة حاليًا',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                ),
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'اختر المادة البديلة',
                  border: OutlineInputBorder(),
                ),
                items: _alternatives
                    .map((c) => DropdownMenuItem<int>(
                          value: (c['id'] as num).toInt(),
                          child: Text(
                            '${c['name'] ?? ''} — ${c['price'] ?? ''} SYP',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _selectedId = v),
              ),
              const SizedBox(height: 12),
              if (_deltaCents > BigInt.zero) ...[
                Text(
                  'فرق السعر: +${_centsToMoney(_deltaCents)} SYP • رصيدك: ${_centsToMoney(_balanceCents)} SYP',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: _insufficientBalance
                          ? AppColors.error
                          : AppColors.textSecondary),
                ),
                if (_insufficientBalance) ...[
                  const SizedBox(height: 4),
                  Text(
                    'رصيدك لا يكفي لهذا التبديل (توفّر الفرق أولاً)',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              CustomTextField(
                labelText: 'سبب الطلب (اختياري)',
                controller: _reasonCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'إرسال طلب التبديل',
                icon: Icons.send_rounded,
                isLoading: _submitting,
                onPressed: _insufficientBalance ? null : _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
