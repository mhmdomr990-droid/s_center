import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'earnings_controller.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EarningsController>(
      init: EarningsController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'الأرباح'),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            return RefreshIndicator(
              onRefresh: ctrl.loadEarnings,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ملخص الأرباح', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStat('الأرباح', '${ctrl.totalEarned.value} SYP'),
                            const SizedBox(width: 16),
                            _buildStat('المدفوع', '${ctrl.totalPaid.value} SYP'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStat('المتبقّي', '${ctrl.remaining.value} SYP'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('سجل الدفعات', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  if (ctrl.payouts.isEmpty)
                    const EmptyState(icon: Icons.payment, title: 'لا توجد دفعات', subtitle: 'لم يتم دفع أي مبلغ لك بعد')
                  else
                    ...ctrl.payouts.map((payout) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.payment, color: AppColors.success, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('دفعة للمدرس', style: AppTextStyles.bodyMedium),
                                if (payout.note != null)
                                  Text(payout.note!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${payout.createdAt?.day}/${payout.createdAt?.month}/${payout.createdAt?.year}', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Text(
                            '+${payout.amount} SYP',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
