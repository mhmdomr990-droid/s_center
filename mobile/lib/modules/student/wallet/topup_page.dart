import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'topup_controller.dart';

class TopupPage extends StatelessWidget {
  const TopupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TopupController>(
      init: TopupController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'شحن رصيد المحفظة'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('أضف رصيدك بسرعة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('اختر طريقة الدفع وأدخل بيانات التحويل',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  labelText: 'المبلغ (SYP)',
                  prefixIcon: Icons.monetization_on_outlined,
                  controller: ctrl.amountCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text('طريقة الدفع', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildMethodChip(ctrl, 'SHAM_CASH', 'Sham Cash', Icons.account_balance_wallet_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMethodChip(ctrl, 'TRANSFER_OFFICE', 'تحويل مكتب', Icons.store_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'رقم المرجع',
                  prefixIcon: Icons.tag,
                  controller: ctrl.referenceCtrl,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'اسم المرسل',
                  prefixIcon: Icons.person_outline,
                  controller: ctrl.senderCtrl,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'ملاحظة (اختياري)',
                  prefixIcon: Icons.note_alt_outlined,
                  controller: ctrl.noteCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Obx(() => CustomButton(
                  text: 'إرسال طلب الشحن',
                  isLoading: ctrl.isLoading.value,
                  onPressed: ctrl.submitTopup,
                  icon: Icons.send,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodChip(TopupController ctrl, String value, String label, IconData icon) {
    final isSelected = ctrl.selectedMethod.value == value;
    return GestureDetector(
      onTap: () => ctrl.selectedMethod.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.courseCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }
}
