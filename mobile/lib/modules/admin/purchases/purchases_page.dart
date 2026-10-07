import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../utils/format.dart';
import 'purchases_controller.dart';

class PurchasesPage extends StatelessWidget {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchasesAdminController>(
      init: PurchasesAdminController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'عمليات الشراء'),
          body: Obx(() {
            final visible = ctrl.filteredItems;
            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomTextField(
                      labelText: 'بحث بالطالب أو الكورس',
                      prefixIcon: Icons.search_rounded,
                      controller: ctrl.searchCtrl,
                      onChanged: ctrl.onSearchChanged,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _filterChip(ctrl, '', 'الكل'),
                        const SizedBox(width: 6),
                        _filterChip(ctrl, 'PURCHASED', 'شراء'),
                        const SizedBox(width: 6),
                        _filterChip(ctrl, 'FREE', 'مجاني'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (ctrl.isLoading.value) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: ctrl.totalUsers.value > 0
                                ? ctrl.loadedUsers.value / ctrl.totalUsers.value
                                : null,
                            color: AppColors.primary,
                            backgroundColor: AppColors.courseCard,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'جارٍ جلب المشتريات… ${ctrl.loadedUsers.value}/${ctrl.totalUsers.value}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    if (ctrl.items.isEmpty) ...[
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: LoadingListShimmer(),
                      ),
                    ],
                  ] else if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'لا توجد عمليات',
                        subtitle: ctrl.hasActiveFilter
                            ? 'جرّب تعديل البحث أو الفلتر'
                            : 'لم يتم تسجيل أي شراء أو منحة مجانية بعد.',
                      ),
                    )
                  else
                    ...visible.map((p) => _buildRow(p)),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _filterChip(PurchasesAdminController ctrl, String type, String label) {
    final isSelected = ctrl.typeFilter.value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.courseCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> p) {
    final free = double.tryParse('${p['price_paid']}') == 0;
    final accent = free ? AppColors.success : AppColors.primary;
    final date = DateTime.tryParse('${p['created_at']}');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.courseCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('${p['full_name'] ?? ''}',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    _typeBadge(free, accent),
                  ],
                ),
                const SizedBox(height: 2),
                Text('@${p['username'] ?? ''} • ${p['course_name'] ?? ''}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                    '${p['specialization_name'] ?? '—'}${date != null ? ' • ${formatArabicDate(date)}' : ''}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${formatAmount(p['price_paid'])} SYP',
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _typeBadge(bool free, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        free ? 'مجاني' : 'شراء',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}
