import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/status_pill.dart';
import '../../../utils/format.dart';
import '../../../data/models/topup_request_model.dart';
import 'wallet_controller.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: WalletController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'المحفظة'),
          body: Obx(() {
            if (ctrl.isLoading.value &&
                ctrl.transactions.isEmpty &&
                ctrl.topupRequests.isEmpty) {
              return const LoadingListShimmer();
            }

            return RefreshIndicator(
              onRefresh: ctrl.loadWallet,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  BalanceCard(
                    balance: ctrl.balance.value,
                    onTopup: () => Get.toNamed(AppRoutes.topup),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(child: StatCard(title: 'إجمالي الشحنات', value: '${formatAmount(ctrl.totalTopups.value)} SYP', icon: Icons.add_circle_outline_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(title: 'إجمالي المشتريات', value: '${formatAmount(ctrl.totalPurchases.value)} SYP', icon: Icons.shopping_cart_outlined)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'طلبات الشحن',
                    icon: Icons.receipt_long_rounded,
                    trailing: ctrl.topupTotal.value > ctrl.topupRequests.length
                        ? Text('${ctrl.topupRequests.length}/${ctrl.topupTotal.value}',
                            style: AppTextStyles.caption)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.topupRequests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: EmptyState(
                        icon: Icons.outbox_rounded,
                        title: 'لا توجد طلبات شحن بعد',
                        subtitle: 'ستظهر طلباتك هنا بمجرد إرسالها',
                      ),
                    )
                  else
                    ...ctrl.topupRequests.map((req) => _buildTopupRequestCard(ctrl, req)),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'سجل الحركات',
                    icon: Icons.swap_horiz_rounded,
                    trailing: ctrl.transactionsTotal.value > ctrl.transactions.length
                        ? Text('${ctrl.transactions.length}/${ctrl.transactionsTotal.value}',
                            style: AppTextStyles.caption)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'لا توجد حركات بعد',
                        subtitle: 'ستظهر حركات المحفظة هنا',
                      ),
                    )
                  else
                    ...ctrl.transactions.map((tx) => RepaintBoundary(
                      child: Container(
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tx.isTopup
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              tx.isTopup ? Icons.add_circle : Icons.shopping_cart,
                              color: tx.isTopup ? AppColors.success : AppColors.error,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.description ?? (tx.isTopup ? 'شحن رصيد' : 'شراء دورة'),
                                    style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(ctrl.formatDate(tx.createdAt), style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isTopup ? '+' : '-'}${formatAmount(tx.amount)}',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: tx.isTopup ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    )),
                  if (ctrl.hasMoreTransactions)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Obx(() => CustomButton(
                            text: ctrl.isLoadingMore.value ? 'جارٍ التحميل...' : 'المزيد',
                            isOutlined: true,
                            isLoading: ctrl.isLoadingMore.value,
                            onPressed: ctrl.loadMoreTransactions,
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

  Widget _buildTopupRequestCard(WalletController ctrl, TopupRequestModel req) {
    final (statusLabel, statusColor) = switch (req.status) {
      'APPROVED' => ('مقبول', AppColors.success),
      'REJECTED' => ('مرفوض', AppColors.error),
      _ => ('معلّق المراجعة', AppColors.warning),
    };

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
                  req.isApproved
                      ? Icons.check_circle_outline
                      : req.isRejected
                          ? Icons.cancel_outlined
                          : Icons.hourglass_top_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${formatAmount(req.amount)} SYP', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('مرجع: ${req.referenceNumber} • ${req.senderName}',
                        style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              StatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          if (req.rejectReason != null && req.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('سبب الرفض: ${req.rejectReason}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ),
          ],
          if (req.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(ctrl.formatDate(req.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 11)),
          ],
        ],
      ),
    ),
    );
  }
}
