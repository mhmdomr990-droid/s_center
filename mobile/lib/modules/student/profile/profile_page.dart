import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../utils/format.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/section_header.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return parts.first.substring(0, 1) + parts.last.substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'حسابي'),
          body: Obx(() {
            final user = ctrl.user.value;
            if (ctrl.isLoading.value && user == null) {
              return const LoadingListShimmer();
            }

            return RefreshIndicator(
              onRefresh: ctrl.loadProfile,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.colored,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _initials(user?.fullName.isNotEmpty == true
                                ? user!.fullName
                                : (user?.username ?? '')),
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName
                                    : (user?.username ?? ''),
                                style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${user?.username ?? ''}',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              if (user?.isTeacher != true)
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white70,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${formatAmount(user?.balance ?? '0.00')} SYP',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'المظهر',
                    icon: Icons.dark_mode_rounded,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
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
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'تغيير كلمة المرور',
                    icon: Icons.lock_reset_rounded,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.courseCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            labelText: 'كلمة المرور الحالية',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: ctrl.obscureOld.value,
                            controller: ctrl.oldPasswordCtrl,
                            suffixIcon: IconButton(
                              icon: Icon(
                                ctrl.obscureOld.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                                size: 22,
                              ),
                              onPressed: () =>
                                  ctrl.obscureOld.value = !ctrl.obscureOld.value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            labelText: 'كلمة المرور الجديدة',
                            prefixIcon: Icons.lock_reset_rounded,
                            obscureText: ctrl.obscureNew.value,
                            controller: ctrl.newPasswordCtrl,
                            suffixIcon: IconButton(
                              icon: Icon(
                                ctrl.obscureNew.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                                size: 22,
                              ),
                              onPressed: () =>
                                  ctrl.obscureNew.value = !ctrl.obscureNew.value,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            labelText: 'تأكيد كلمة المرور الجديدة',
                            prefixIcon: Icons.lock_reset_rounded,
                            obscureText: ctrl.obscureConfirm.value,
                            controller: ctrl.confirmPasswordCtrl,
                            suffixIcon: IconButton(
                              icon: Icon(
                                ctrl.obscureConfirm.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                                size: 22,
                              ),
                              onPressed: () => ctrl.obscureConfirm.value =
                                  !ctrl.obscureConfirm.value,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'حفظ كلمة المرور الجديدة',
                            icon: Icons.save_outlined,
                            isLoading: ctrl.isChangingPassword.value,
                            onPressed: ctrl.changePassword,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'الجلسات والأجهزة',
                    icon: Icons.devices_other_rounded,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.courseCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        children: [
                          CustomButton(
                            text: 'تسجيل الخروج',
                            icon: Icons.logout_rounded,
                            isOutlined: true,
                            isLoading: ctrl.isLoggingOut.value,
                            onPressed: () => ctrl.logout(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: ctrl.isLoggingOut.value
                                  ? null
                                  : () => ctrl.logout(fromAllDevices: true),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.error, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.devices_other_rounded,
                                      size: 20, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تسجيل الخروج من كل الأجهزة',
                                    style: AppTextStyles.button
                                        .copyWith(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
