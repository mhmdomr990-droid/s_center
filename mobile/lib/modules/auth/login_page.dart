import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.checkAuth());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, size: 60, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Obx(() => Text(
                    ctrl.loginRole.value == 'TEACHER' ? 'دخول المعلمين' : 'مرحباً بعودتك',
                    style: AppTextStyles.headlineLarge,
                  )),
              const SizedBox(height: 8),
              Obx(() => Text(
                    ctrl.loginRole.value == 'TEACHER'
                        ? 'سجّل دخولك لإدارة دوراتك ومحاضراتك'
                        : 'سجّل دخولك للوصول لدوراتك',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  )),
              const SizedBox(height: 24),
              Obx(() => Row(
                    children: [
                      _buildRoleTab(ctrl, 'STUDENT', 'طالب', Icons.school_outlined),
                      const SizedBox(width: 12),
                      _buildRoleTab(ctrl, 'TEACHER', 'معلم', Icons.menu_book_outlined),
                    ],
                  )),
              const SizedBox(height: 24),
              Form(
                child: Column(
                  children: [
                    CustomTextField(
                      labelText: 'اسم المستخدم',
                      prefixIcon: Icons.person_outline,
                      controller: ctrl.loginUsernameCtrl,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => CustomTextField(
                      labelText: 'كلمة المرور',
                      prefixIcon: Icons.lock_outline,
                      obscureText: ctrl.obscurePassword.value,
                      controller: ctrl.loginPasswordCtrl,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ctrl.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textHint,
                          size: 22,
                        ),
                        onPressed: () => ctrl.obscurePassword.toggle(),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Obx(() => CustomButton(
                    text: ctrl.loginRole.value == 'TEACHER' ? 'دخول المعلم' : 'تسجيل الدخول',
                    isLoading: ctrl.isLoading.value,
                    onPressed: ctrl.login,
                    icon: Icons.login,
                  )),
              const SizedBox(height: 20),
              Obx(() {
                if (ctrl.loginRole.value == 'TEACHER') return const SizedBox.shrink();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ليس لديك حساب؟ ', style: AppTextStyles.bodyMedium),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.register),
                      child: Text(
                        'سجّل الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(AuthController ctrl, String role, String label, IconData icon) {
    final isSelected = ctrl.loginRole.value == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.loginRole.value = role,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.courseCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
