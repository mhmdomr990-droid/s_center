import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/providers/api_client.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'admin_account_controller.dart';

class AdminAccountPage extends StatelessWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminAccountController>(
      init: AdminAccountController(),
      builder: (ctrl) {
        final user = ctrl.auth.user.value;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'حسابي'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 12),
                    Text(user?.fullName ?? '—',
                        style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('@${user?.username ?? ''} • حساب إداري',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    if (user?.balance != null) ...[
                      const SizedBox(height: 8),
                      Text('الرصيد: ${user!.balance} SYP',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => CustomButton(
                    text: 'تغيير كلمة المرور',
                    icon: Icons.lock_outline,
                    isOutlined: true,
                    isLoading: ctrl.isChangingPassword.value,
                    onPressed: ctrl.changePassword,
                  )),
              const SizedBox(height: 12),
              CustomButton(
                text: 'تسجيل الخروج',
                icon: Icons.logout_rounded,
                backgroundColor: AppColors.error,
                onPressed: ctrl.logout,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.courseCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('عنوان الخادم', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    SelectableText(ApiClient.baseUrl,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
