import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/loading_shimmer.dart';
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
          appBar: AppBar(title: const Text('المحفظة')),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

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
                        Expanded(child: StatCard(title: 'إجمالي الشحنات', value: '${ctrl.totalTopups.value} SYP', icon: Icons.add_circle_outline)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(title: 'إجمالي المشتريات', value: '${ctrl.totalPurchases.value} SYP', icon: Icons.shopping_cart_outlined)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('سجل الحركات', style: AppTextStyles.titleLarge),
                  ),
                  const SizedBox(height: 8),
                  if (ctrl.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('لا توجد حركات بعد', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...ctrl.transactions.map((tx) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
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
                            '${tx.isTopup ? '+' : '-'}${tx.amount}',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: tx.isTopup ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    )),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
