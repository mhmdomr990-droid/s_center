import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/section_header.dart';
import '../../../utils/format.dart';
import 'teacher_detail_controller.dart';

class TeacherDetailPage extends StatelessWidget {
  const TeacherDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherDetailController>(
      init: TeacherDetailController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'تفاصيل المعلم'),
          body: Obx(() {
            if (ctrl.isLoading.value || ctrl.teacher.value == null) {
              return const LoadingListShimmer();
            }
            final t = ctrl.teacher.value!;
            final totals = Map<String, dynamic>.from(t['totals'] ?? {});
            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.courseCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Text(t['full_name'] ?? '', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text('@${t['username'] ?? ''}', style: AppTextStyles.caption),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _stat('الأرباح', formatAmount(totals['earned'])),
                            _stat('المدفوع', formatAmount(totals['paid'])),
                            _stat('المتبقي', formatAmount(totals['remaining']),
                                color: AppColors.success),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      text: 'تسجيل دفعة',
                      icon: Icons.payments_outlined,
                      onPressed: ctrl.busy.value ? null : ctrl.addPayout,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'دورات المعلم',
                    icon: Icons.menu_book_rounded,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${ctrl.courses.length}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.courses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'لا توجد دورات',
                        subtitle: 'لم يُسند أي دورة لهذا المعلم',
                      ),
                    )
                  else
                    ...ctrl.courses.map((c) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.courseCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.play_lesson_outlined,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name'] ?? '',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(
                                      'نسبة المعلم: ${_percentLabel('${c['teacher_percent'] ?? '0'}')}%',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Text(formatAmount(c['price']),
                                  style: AppTextStyles.caption
                                      .copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'سجل الدفعات', icon: Icons.receipt_long_rounded),
                  const SizedBox(height: 8),
                  if (ctrl.payouts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: EmptyState(
                        icon: Icons.payments_outlined,
                        title: 'لا توجد دفعات',
                        subtitle: 'ستظهر الدفعات المسجلة هنا',
                      ),
                    )
                  else
                    ...ctrl.payouts.map((p) {
                      final date = DateTime.tryParse(p['created_at']?.toString() ?? '');
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.courseCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money_rounded,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p['note'] != null && '${p['note']}'.isNotEmpty)
                                    Text('${p['note']}',
                                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                                  if (date != null)
                                    Text(formatArabicDate(date), style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            Text(formatAmount(p['amount']),
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  String _percentLabel(String value) {
    var v = value.trim();
    if (v.contains('.')) {
      v = v.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return v.isEmpty ? '0' : v;
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
