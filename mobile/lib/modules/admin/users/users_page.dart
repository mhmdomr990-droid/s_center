import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../utils/format.dart';
import 'users_controller.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UsersController>(
      init: UsersController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            title: 'المستخدمون',
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                tooltip: 'طالب جديد',
                onPressed: () => _showCreateStudentDialog(context, ctrl),
              ),
            ],
          ),
          body: Obx(() {
            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomTextField(
                      labelText: 'بحث بالاسم أو اسم المستخدم',
                      prefixIcon: Icons.search_rounded,
                      controller: ctrl.searchCtrl,
                      onChanged: ctrl.onSearchChanged,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _filterChip(ctrl, '', 'الكل'),
                        const SizedBox(width: 6),
                        _filterChip(ctrl, 'STUDENT', 'طلاب'),
                        const SizedBox(width: 6),
                        _filterChip(ctrl, 'TEACHER', 'معلمون'),
                        const SizedBox(width: 6),
                        _filterChip(ctrl, 'ADMIN', 'إداريون'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (ctrl.isLoading.value && ctrl.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: LoadingListShimmer(),
                    )
                  else if (ctrl.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.group_off_outlined,
                        title: 'لا يوجد مستخدمون',
                        subtitle: 'جرّب تعديل البحث أو الفلتر',
                      ),
                    )
                  else
                    ...ctrl.items.map((u) => _buildUserCard(ctrl, u)),
                  if (ctrl.hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Obx(() => CustomButton(
                            text: ctrl.isLoadingMore.value ? 'جارٍ التحميل...' : 'المزيد',
                            isOutlined: true,
                            isLoading: ctrl.isLoadingMore.value,
                            onPressed: ctrl.loadMore,
                          )),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _filterChip(UsersController ctrl, String role, String label) {
    final isSelected = ctrl.roleFilter.value == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.setRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
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
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UsersController ctrl, Map<String, dynamic> u) {
    final isActive = u['is_active'] ?? true;
    final role = (u['role'] ?? 'STUDENT') as String;
    final roleColor = switch (role) {
      'ADMIN' => AppColors.error,
      'TEACHER' => AppColors.primary,
      _ => AppColors.success,
    };

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => ctrl.openDetail(u['id'] as int),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.courseCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.cardBorder : AppColors.error.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'TEACHER'
                      ? Icons.school_outlined
                      : role == 'ADMIN'
                          ? Icons.admin_panel_settings_outlined
                          : Icons.person_outline,
                  color: roleColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(u['full_name'] ?? '',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 6),
                          const Text('معطّل',
                              style: TextStyle(color: AppColors.error, fontSize: 11)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('@${u['username'] ?? ''} • ${ctrl.roleLabel(role)}',
                        style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (role == 'STUDENT') ...[
                      const SizedBox(height: 2),
                      Text(
                        '${u['specialization_name'] ?? ''}'.isNotEmpty
                            ? 'الاختصاص: ${u['specialization_name']}'
                            : 'بلا اختصاص',
                        style: AppTextStyles.caption.copyWith(
                          color: '${u['specialization_name'] ?? ''}'.isNotEmpty
                              ? AppColors.textSecondary
                              : AppColors.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${formatAmount(u['balance'])} SYP',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Icon(Icons.chevron_left_rounded, color: AppColors.textHint, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showCreateStudentDialog(BuildContext context, UsersController ctrl) {
    final fullNameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int? selectedSpec;

    // تحميل طازج عند كل فتح — حتى يظهر أي تخصص أُضيف حديثاً
    // من تبويب المحتوى دون الحاجة لتسجيل الخروج والدخول
    unawaited(ctrl.loadSpecializations());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('طالب جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الاسم الكامل', border: OutlineInputBorder()),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final specs = ctrl.specializations;
                    if (specs.isEmpty) {
                      return Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text('جارٍ تحميل الاختصاصات...',
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 12, color: AppColors.textHint)),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              await ctrl.loadSpecializations();
                            },
                            child: const Text('إعادة المحاولة', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      );
                    }
                    return DropdownButtonFormField<int>(
                      initialValue: selectedSpec,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'الاختصاص *',
                        border: OutlineInputBorder(),
                      ),
                      items: specs
                          .map((s) => DropdownMenuItem<int>(
                                value: (s['id'] as num).toInt(),
                                child: Text('${s['name'] ?? ''}',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedSpec = value),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء')),
              TextButton(
                onPressed: () {
                  final username = usernameCtrl.text.trim().toLowerCase();
                  final fullName = fullNameCtrl.text.trim();
                  final password = passwordCtrl.text;
                  final phone = phoneCtrl.text.trim();
                  if (username.length < 3 ||
                      !RegExp(r'^[a-z0-9_]+$').hasMatch(username) ||
                      fullName.length < 2 ||
                      password.length < 8) {
                    Get.snackbar('خطأ',
                        'تحقق من البيانات (المستخدم ≥3 أحرف صغيرة، الاسم ≥2، كلمة المرور ≥8)',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }
                  if (phone.isNotEmpty &&
                      !RegExp(r'^\+?[0-9\s\-()]{7,30}$').hasMatch(phone)) {
                    Get.snackbar('خطأ', 'رقم الهاتف غير صالح',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }
                  if (selectedSpec == null) {
                    Get.snackbar('خطأ', 'اختر اختصاص الطالب',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  ctrl.createStudent(
                    username: username,
                    fullName: fullName,
                    password: password,
                    phone: phone,
                    specializationId: selectedSpec!,
                  );
                },
                child: const Text('إنشاء'),
              ),
            ],
          );
        },
      ),
    );
  }
}
