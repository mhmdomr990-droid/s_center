import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../utils/format.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import 'swap_requests_controller.dart';

class SwapRequestsPage extends StatelessWidget {
  const SwapRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SwapRequestsAdminController>(
      init: SwapRequestsAdminController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'طلبات تبديل المواد'),
          body: Obx(() {
            if (ctrl.isLoading.value && ctrl.items.isEmpty) {
              return const LoadingListShimmer();
            }
            if (ctrl.items.isEmpty) {
              return const EmptyState(
                icon: Icons.swap_horiz_rounded,
                title: 'لا توجد طلبات تبديل',
                subtitle: 'لا توجد طلبات بانتظار المراجعة حالياً',
              );
            }
            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ctrl.items.length,
                itemBuilder: (context, i) => _SwapRequestCard(
                  item: ctrl.items[i],
                  busy: ctrl.busy.value,
                  onApprove: () => ctrl.approve(ctrl.items[i]),
                  onReject: () => ctrl.reject(ctrl.items[i]),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SwapRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SwapRequestCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${item['requested_at']}');
    final reason = '${item['reason'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.courseCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${item['student_name'] ?? ''}',
                    style: AppTextStyles.titleMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              if (date != null)
                Text(formatArabicDate(date),
                    style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
          if ('${item['username'] ?? ''}'.isNotEmpty)
            Text('@${item['username']}',
                style: AppTextStyles.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 10),
          _CourseRow(
              icon: Icons.remove_circle_outline_rounded,
              color: AppColors.error,
              label: 'من',
              course: '${item['old_course_name'] ?? '-'}'),
          const SizedBox(height: 4),
          _CourseRow(
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.success,
              label: 'إلى',
              course: '${item['new_course_name'] ?? '-'}'),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('السبب: $reason',
                  style: AppTextStyles.caption.copyWith(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'موافقة',
                  icon: Icons.check_rounded,
                  isLoading: busy,
                  onPressed: onApprove,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'رفض',
                  icon: Icons.close_rounded,
                  isOutlined: true,
                  backgroundColor: AppColors.error,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String course;

  const _CourseRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text('$label: ', style: AppTextStyles.caption.copyWith(fontSize: 12)),
        Expanded(
          child: Text(course,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
