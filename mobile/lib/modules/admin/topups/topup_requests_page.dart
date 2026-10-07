import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_pill.dart';
import '../../../utils/format.dart';
import 'topup_requests_controller.dart';

class TopupRequestsPage extends StatelessWidget {
  const TopupRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TopupRequestsController>(
      init: TopupRequestsController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            title: 'طلبات الشحن',
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                tooltip: 'عمليات الشراء',
                onPressed: () => Get.toNamed(AppRoutes.adminPurchases),
              ),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value && ctrl.items.isEmpty) {
              return const LoadingListShimmer();
            }
            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _filterChip(ctrl, 'PENDING', 'معلّقة'),
                        const SizedBox(width: 8),
                        _filterChip(ctrl, 'APPROVED', 'مقبولة'),
                        const SizedBox(width: 8),
                        _filterChip(ctrl, 'REJECTED', 'مرفوضة'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'الطلبات',
                    icon: Icons.receipt_long_rounded,
                    trailing: ctrl.total.value > ctrl.items.length
                        ? Text('${ctrl.items.length}/${ctrl.total.value}',
                            style: AppTextStyles.caption)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.inbox_rounded,
                        title: 'لا توجد طلبات هنا',
                        subtitle: 'ستظهر الطلبات فور وصولها',
                      ),
                    )
                  else
                    ...ctrl.items.map((req) => _buildRequestCard(ctrl, req)),
                  if (ctrl.hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Obx(() => CustomButton(
                            text: ctrl.isLoadingMore.value ? 'جارٍ التحميل...' : 'المزيد',
                            isOutlined: true,
                            isLoading: ctrl.isLoadingMore.value,
                            onPressed: ctrl.loadMore,
                          )),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _filterChip(TopupRequestsController ctrl, String status, String label) {
    final isSelected = ctrl.statusFilter.value == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setStatus(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(TopupRequestsController ctrl, Map<String, dynamic> req) {
    final status = (req['status'] ?? 'PENDING') as String;
    final (statusLabel, statusColor) = switch (status) {
      'APPROVED' => ('مقبول', AppColors.success),
      'REJECTED' => ('مرفوض', AppColors.error),
      _ => ('معلّق', AppColors.warning),
    };
    final isPending = status == 'PENDING';
    final createdAt = DateTime.tryParse(req['created_at']?.toString() ?? '');

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.courseCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPending
                        ? Icons.hourglass_top_rounded
                        : status == 'APPROVED'
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                    color: statusColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${formatAmount(req['amount'])} SYP',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${req['full_name'] ?? ''} (${req['username'] ?? ''})',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('الطريقة', req['method'] == 'TRANSFER_OFFICE' ? 'تحويل مكتب' : 'Sham Cash'),
            _infoRow('المرجع', '${req['reference_number'] ?? ''}'),
            _infoRow('المرسل', '${req['sender_name'] ?? ''}'),
            if (req['note'] != null && '${req['note']}'.isNotEmpty)
              _infoRow('ملاحظة', '${req['note']}'),
            if (req['reject_reason'] != null && '${req['reject_reason']}'.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('سبب الرفض: ${req['reject_reason']}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.error)),
              ),
            if (createdAt != null) ...[
              const SizedBox(height: 6),
              Text(formatArabicDate(createdAt),
                  style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'موافقة',
                      backgroundColor: AppColors.success,
                      onPressed: () => ctrl.approve(req),
                      icon: Icons.check_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'رفض',
                      isOutlined: true,
                      backgroundColor: AppColors.error,
                      onPressed: () => ctrl.reject(req),
                      icon: Icons.close_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}
