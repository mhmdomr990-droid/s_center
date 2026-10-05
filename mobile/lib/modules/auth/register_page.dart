import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'auth_controller.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.textPrimary,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('إنشاء حساب جديد', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 8),
                  Text('أدخل بياناتك للتسجيل', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  Form(
                    child: Column(
                      children: [
                        CustomTextField(
                          labelText: 'اسم المستخدم',
                          prefixIcon: Icons.alternate_email,
                          controller: ctrl.registerUsernameCtrl,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icons.badge_outlined,
                          controller: ctrl.registerFullNameCtrl,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                        Obx(() => CustomTextField(
                          labelText: 'كلمة المرور',
                          prefixIcon: Icons.lock_outline,
                          obscureText: ctrl.obscurePassword.value,
                          controller: ctrl.registerPasswordCtrl,
                          suffixIcon: IconButton(
                            icon: Icon(
                              ctrl.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textHint,
                              size: 22,
                            ),
                            onPressed: () => ctrl.obscurePassword.toggle(),
                          ),
                        )),
                        const SizedBox(height: 16),
                        Obx(() => CustomTextField(
                          labelText: 'تأكيد كلمة المرور',
                          prefixIcon: Icons.lock_outline,
                          obscureText: ctrl.obscureConfirmPassword.value,
                          controller: ctrl.registerConfirmCtrl,
                          suffixIcon: IconButton(
                            icon: Icon(
                              ctrl.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textHint,
                              size: 22,
                            ),
                            onPressed: () => ctrl.obscureConfirmPassword.toggle(),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(() => CustomButton(
                    text: 'سجّل الآن',
                    isLoading: ctrl.isLoading.value,
                    onPressed: ctrl.register,
                    icon: Icons.person_add,
                  )),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('لديك حساب بالفعل؟ ', style: AppTextStyles.bodyMedium),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'سجّل دخولك',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
