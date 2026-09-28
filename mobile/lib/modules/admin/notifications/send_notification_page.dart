import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'send_notification_controller.dart';

class SendNotificationPage extends StatelessWidget {
  const SendNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SendNotificationController>(
      init: SendNotificationController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'إرسال إشعار'),
          body: Obx(() {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _targetChip(ctrl, true, 'للجميع'),
                      const SizedBox(width: 10),
                      _targetChip(ctrl, false, 'لمستخدم محدد'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!ctrl.sendToAll.value) ...[
                    if (ctrl.selectedUser.value != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${ctrl.selectedUser.value!['full_name']} (@${ctrl.selectedUser.value!['username']})',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => ctrl.selectedUser.value = null,
                            ),
                          ],
                        ),
                      )
                    else ...[
                      CustomTextField(
                        labelText: 'ابحث عن مستخدم (اسم أو مستخدم)',
                        prefixIcon: Icons.search_rounded,
                        controller: ctrl.searchCtrl,
                        onChanged: ctrl.onSearchChanged,
                      ),
                      if (ctrl.isLoading.value)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      else if (ctrl.searchCtrl.text.isNotEmpty && ctrl.candidates.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: AppColors.courseCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: ctrl.candidates.length,
                            itemBuilder: (context, index) {
                              final u = ctrl.candidates[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.person_outline, size: 20),
                                title: Text('${u['full_name']}',
                                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                                subtitle: Text('@${u['username']}',
                                    style: AppTextStyles.caption),
                                onTap: () => ctrl.selectUser(u),
                              );
                            },
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    labelText: 'عنوان الإشعار',
                    prefixIcon: Icons.title_rounded,
                    controller: ctrl.titleCtrl,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    labelText: 'نص الإشعار',
                    prefixIcon: Icons.notes_rounded,
                    controller: ctrl.bodyCtrl,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  Obx(() => CustomButton(
                        text: 'إرسال الإشعار',
                        isLoading: ctrl.isSubmitting.value,
                        onPressed: ctrl.submit,
                        icon: Icons.send_rounded,
                      )),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _targetChip(SendNotificationController ctrl, bool all, String label) {
    final isSelected = ctrl.sendToAll.value == all;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setSendToAll(all),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.courseCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
