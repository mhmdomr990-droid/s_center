import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../utils/format.dart';
import 'teachers_controller.dart';

class TeachersPage extends StatelessWidget {
  const TeachersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeachersController>(
      init: TeachersController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            title: 'المدرسون',
            actions: [
              IconButton(
                tooltip: 'معلم جديد',
                icon: const Icon(Icons.person_add_alt_1_rounded),
                onPressed: () => _showCreateDialog(context, ctrl),
              ),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value && ctrl.items.isEmpty) {
              return const LoadingListShimmer();
            }
            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  if (ctrl.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.school_outlined,
                        title: 'لا يوجد مدرسون',
                        subtitle: 'أضف أول معلم من الأعلى',
                      ),
                    )
                  else
                    ...ctrl.items.map((t) {
                      final teacherId = (t['teacher_id'] ?? t['id']) as int;
                      return RepaintBoundary(
                        child: GestureDetector(
                          onTap: () => ctrl.openDetail(teacherId),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.courseCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.school_outlined,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t['full_name'] ?? '',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('@${t['username'] ?? ''}',
                                          style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('متبقي: ${formatAmount(t['remaining'])}',
                                        style: AppTextStyles.caption
                                            .copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('أرباح: ${formatAmount(t['earned'])}',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_left_rounded,
                                    color: AppColors.textHint, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  static void _showCreateDialog(BuildContext context, TeachersController ctrl) {
    final usernameCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('معلم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fullNameCtrl,
              decoration:
                  const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم (أحرف صغيرة وأرقام و_)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور (8 أحرف على الأقل)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final username = usernameCtrl.text.trim().toLowerCase();
              final fullName = fullNameCtrl.text.trim();
              final password = passwordCtrl.text;
              if (username.length < 3 || fullName.length < 2 || password.length < 8) {
                Get.snackbar('خطأ', 'تحقق من البيانات (المستخدم ≥3، الاسم ≥2، كلمة المرور ≥8)',
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              Navigator.of(dialogContext).pop();
              ctrl.createTeacher(username: username, fullName: fullName, password: password);
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }
}
