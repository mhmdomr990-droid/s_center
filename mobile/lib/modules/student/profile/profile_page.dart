import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_shimmer.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('حسابي')),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            final user = ctrl.user.value;

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
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName.isNotEmpty == true ? user!.fullName : (user?.username ?? ''),
                                style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${user?.username ?? ''}',
                                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${user?.balance ?? '0.00'} SYP',
                                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('تغيير كلمة المرور', style: AppTextStyles.titleLarge),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomTextField(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: Icons.lock_outline,
                      obscureText: ctrl.obscureOld.value,
                      controller: ctrl.oldPasswordCtrl,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ctrl.obscureOld.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textHint,
                          size: 22,
                        ),
                        onPressed: () => ctrl.obscureOld.value = !ctrl.obscureOld.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomTextField(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: Icons.lock_reset,
                      obscureText: ctrl.obscureNew.value,
                      controller: ctrl.newPasswordCtrl,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ctrl.obscureNew.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textHint,
                          size: 22,
                        ),
                        onPressed: () => ctrl.obscureNew.value = !ctrl.obscureNew.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomTextField(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      prefixIcon: Icons.lock_reset,
                      obscureText: ctrl.obscureConfirm.value,
                      controller: ctrl.confirmPasswordCtrl,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ctrl.obscureConfirm.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textHint,
                          size: 22,
                        ),
                        onPressed: () => ctrl.obscureConfirm.value = !ctrl.obscureConfirm.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      text: 'حفظ كلمة المرور الجديدة',
                      icon: Icons.save_outlined,
                      isLoading: ctrl.isChangingPassword.value,
                      onPressed: ctrl.changePassword,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(indent: 16, endIndent: 16),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      text: 'تسجيل الخروج',
                      icon: Icons.logout_rounded,
                      isOutlined: true,
                      isLoading: ctrl.isLoggingOut.value,
                      onPressed: () => ctrl.logout(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: ctrl.isLoggingOut.value ? null : () => ctrl.logout(fromAllDevices: true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.devices_other_rounded, size: 20, color: AppColors.error),
                            const SizedBox(width: 8),
                            Text(
                              'تسجيل الخروج من كل الأجهزة',
                              style: AppTextStyles.button.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
