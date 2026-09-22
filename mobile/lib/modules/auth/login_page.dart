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
              Text('مرحباً بعودتك', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text('سجّل دخولك للوصول لدوراتك', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 48),
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
                text: 'تسجيل الدخول',
                isLoading: ctrl.isLoading.value,
                onPressed: ctrl.login,
                icon: Icons.login,
              )),
              const SizedBox(height: 20),
              Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
