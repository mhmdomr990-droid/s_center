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
          appBar: const GradientAppBar(title: 'المستخدمون'),
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
}
