import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/catalog_provider.dart';
import '../../../data/providers/purchase_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

// نافذة تبديل المادة (مطابقة لسلوك الويب): المواد البديلة من نفس الاختصاص
// + سبب اختياري ⇐ POST /course-swap-requests
class SwapCourseSheet extends StatefulWidget {
  final PurchaseModel course;
  final VoidCallback? onSubmitted;

  const SwapCourseSheet({super.key, required this.course, this.onSubmitted});

  static Future<void> show(PurchaseModel course, {VoidCallback? onSubmitted}) {
    return Get.bottomSheet(
      SwapCourseSheet(course: course, onSubmitted: onSubmitted),
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
        _alternatives = data
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
            .where((c) => (c['id'] as num?)?.toInt() != widget.course.courseId)
            .toList();
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

  Future<void> _submit() async {
    if (_selectedId == null) {
      Get.snackbar('تبديل المادة', 'اختر المادة البديلة أولاً',
          backgroundColor: Colors.orange, colorText: Colors.white);
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
      widget.onSubmitted?.call();
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
                onPressed: _submit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
