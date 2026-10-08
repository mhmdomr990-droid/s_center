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
                        Obx(() {
                          if (ctrl.isLoadingSpecializations.value) {
                            return Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('جارٍ تحميل الاختصاصات...',
                                      style: GoogleFonts.cairo(
                                          fontSize: 14, color: AppColors.textHint)),
                                ],
                              ),
                            );
                          }
                          if (ctrl.specializationsError.value != null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('تعذر تحميل الاختصاصات',
                                        style: GoogleFonts.cairo(
                                            fontSize: 13, color: AppColors.textPrimary)),
                                  ),
                                  TextButton(
                                    onPressed: ctrl.loadSpecializations,
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            initialValue: ctrl.registerSpecializationId.value,
                            isExpanded: true,
                            style: GoogleFonts.cairo(
                                fontSize: 15, color: AppColors.textPrimary),
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textHint),
                            decoration: InputDecoration(
                              labelText: 'الاختصاص *',
                              labelStyle: GoogleFonts.cairo(
                                  color: AppColors.textHint),
                              prefixIcon: Icon(Icons.category_outlined,
                                  color: AppColors.textHint, size: 22),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.divider),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                            ),
                            items: [
                              DropdownMenuItem<int>(
                                value: null,
                                child: Text('اختر الاختصاص',
                                    style: TextStyle(color: AppColors.textHint)),
                              ),
                              ...ctrl.specializations.map((s) =>
                                  DropdownMenuItem<int>(
                                      value: s.id, child: Text(s.name))),
                            ],
                            onChanged: (value) =>
                                ctrl.registerSpecializationId.value = value,
                          );
                        }),
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
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'رقم الهاتف (اختياري)',
                          prefixIcon: Icons.phone_outlined,
                          controller: ctrl.registerPhoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(() => CustomButton(
                    text: 'سجّل الآن',
                    isLoading: ctrl.isLoading.value,
                    onPressed: ctrl.isLoadingSpecializations.value ||
                            ctrl.specializationsError.value != null ||
                            ctrl.registerSpecializationId.value == null
                        ? null
                        : ctrl.register,
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
