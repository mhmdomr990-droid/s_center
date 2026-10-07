import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/section_header.dart';
import 'teacher_account_controller.dart';

class TeacherAccountPage extends StatelessWidget {
  const TeacherAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherAccountController>(
      init: TeacherAccountController(),
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
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 12),
                    Text(user?.fullName ?? '—',
                        style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('@${user?.username ?? ''} • حساب معلم',
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
              const SectionHeader(
                title: 'المظهر',
                icon: Icons.dark_mode_rounded,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.courseCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppShadows.soft,
                ),
                child: Obx(() {
                  final themeCtrl = Get.find<ThemeController>();
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'الوضع الليلي',
                      style: AppTextStyles.titleMedium,
                    ),
                    subtitle: Text(
                      'خلفية داكنة مريحة للعين',
                      style: AppTextStyles.bodySmall,
                    ),
                    value: themeCtrl.isDark,
                    activeThumbColor: AppColors.primary,
                    onChanged: themeCtrl.toggle,
                  );
                }),
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
            ],
          ),
        );
      },
    );
  }
}
