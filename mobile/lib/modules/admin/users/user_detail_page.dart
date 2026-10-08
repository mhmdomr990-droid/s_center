import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../utils/format.dart';
import 'user_detail_controller.dart';

class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UserDetailController>(
      init: UserDetailController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'تفاصيل المستخدم'),
          body: Obx(() {
            if (ctrl.isLoading.value || ctrl.user.value == null) {
              return const LoadingListShimmer();
            }
            final u = ctrl.user.value!;
            final isActive = u['is_active'] ?? true;
            final role = (u['role'] ?? 'STUDENT') as String;
            final isTeacher = role == 'TEACHER';
            final teacherTotals =
                isTeacher ? ctrl.teacherTotals.value : null;
            final roleLabel = switch (role) {
              'ADMIN' => 'إداري',
              'TEACHER' => 'معلم',
              _ => 'طالب',
            };

            return RefreshIndicator(
              onRefresh: ctrl.load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.courseCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            (u['full_name'] ?? '?').toString().isEmpty
                                ? '?'
                                : (u['full_name'] as String).trim()[0],
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(u['full_name'] ?? '', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        Text('@${u['username'] ?? ''} • $roleLabel',
                            style: AppTextStyles.caption),
                        if ('${u['specialization_name'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('الاختصاص: ${u['specialization_name']}',
                              style: AppTextStyles.caption),
                        ],
                        if ('${u['phone'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('${u['phone']}', style: AppTextStyles.caption),
                        ],
                        const SizedBox(height: 12),
                        if (teacherTotals != null) ...[
                          Row(
                            children: [
                              Expanded(
                                  child: _stat('الأرباح',
                                      '${formatAmount(teacherTotals['earned'])} SYP')),
                              Expanded(
                                  child: _stat('المدفوع',
                                      '${formatAmount(teacherTotals['paid'])} SYP')),
                              Expanded(
                                  child: _stat('الباقي',
                                      '${formatAmount(teacherTotals['remaining'])} SYP')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: _stat('المشتريات',
                                      '${teacherTotals['purchases_count'] ?? 0}')),
                              Expanded(
                                child: _stat('الحالة',
                                    isActive ? 'مفعّل' : 'معطّل',
                                    color: isActive
                                        ? AppColors.success
                                        : AppColors.error),
                              ),
                            ],
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(child: _stat('الرصيد', '${formatAmount(u['balance'])} SYP')),
                              Expanded(child: _stat('المشتريات', '${u['purchases_count'] ?? 0}')),
                              Expanded(
                                child: _stat('الحالة', isActive ? 'مفعّل' : 'معطّل',
                                    color: isActive ? AppColors.success : AppColors.error),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: isActive ? 'تعطيل' : 'تفعيل',
                            isOutlined: !isActive,
                            backgroundColor: isActive ? AppColors.error : AppColors.success,
                            onPressed: ctrl.busy.value ? null : ctrl.toggleActive,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: 'تسوية رصيد',
                            isOutlined: true,
                            onPressed: ctrl.busy.value ? null : ctrl.adjustBalance,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'إعادة تعيين الجهاز',
                            isOutlined: true,
                            onPressed: ctrl.busy.value ? null : ctrl.resetDevice,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: 'كلمة مرور جديدة',
                            isOutlined: true,
                            onPressed: ctrl.busy.value ? null : ctrl.resetPassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isTeacher)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: CustomButton(
                        text: 'منح كورس مجاني',
                        icon: Icons.card_giftcard_outlined,
                        isOutlined: true,
                        onPressed:
                            ctrl.busy.value ? null : ctrl.openGrantSheet,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: isTeacher
                          ? [
                              _tabChip(ctrl, 0, 'سجل الدفعات'),
                              const SizedBox(width: 8),
                              _tabChip(ctrl, 1, 'سجل الدورات'),
                            ]
                          : [
                              _tabChip(ctrl, 0, 'الحركات'),
                              const SizedBox(width: 8),
                              _tabChip(ctrl, 1, 'المشتريات'),
                            ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isTeacher) ...[
                    if (ctrl.tab.value == 0) ...[
                      if (ctrl.teacherPayouts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: EmptyState(
                            icon: Icons.payments_outlined,
                            title: 'لا توجد دفعات',
                            subtitle: 'ستظهر الدفعات المسجلة هنا',
                          ),
                        )
                      else
                        ...ctrl.teacherPayouts.map((p) => _payoutRow(p)),
                    ] else ...[
                      if (ctrl.teacherCourses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'لا توجد دورات',
                            subtitle: 'لم يُسند أي دورة لهذا المعلم',
                          ),
                        )
                      else
                        ...ctrl.teacherCourses.map((c) => _teacherCourseRow(c)),
                    ],
                  ] else if (ctrl.tab.value == 0) ...[
                    if (ctrl.transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'لا توجد حركات',
                          subtitle: 'ستظهر حركات المحفظة هنا',
                        ),
                      )
                    else
                      ...ctrl.transactions.map((tx) => _txRow(tx)),
                  ] else ...[
                    if (ctrl.purchases.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: EmptyState(
                          icon: Icons.shopping_cart_outlined,
                          title: 'لا توجد مشتريات',
                          subtitle: 'ستظهر مشتريات الدورات هنا',
                        ),
                      )
                    else
                      ...ctrl.purchases.map((p) => _purchaseRow(ctrl, p)),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _tabChip(UserDetailController ctrl, int index, String label) {
    final isSelected = ctrl.tab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.tab.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
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

  static const _purchasedPrefix = 'Purchased course:';
  static const _topupPrefix = 'Top-up request approved:';

  String _txLabel(Map<String, dynamic> tx) {
    final type = (tx['type'] ?? '').toString();
    final raw = (tx['description'] ?? '').toString().trim();
    if (raw.startsWith(_purchasedPrefix)) {
      return 'شراء دورة: ${raw.substring(_purchasedPrefix.length).trim()}';
    }
    if (raw.startsWith(_topupPrefix)) {
      return 'تمت الموافقة على شحن الرصيد — مرجع: ${raw.substring(_topupPrefix.length).trim()}';
    }
    if (raw.isNotEmpty) return raw;
    return type == 'TOPUP' ? 'شحن رصيد' : 'شراء دورة';
  }

  Widget _txRow(Map<String, dynamic> tx) {
    final isTopup = (tx['type'] ?? '') == 'TOPUP';
    final date = DateTime.tryParse(tx['created_at']?.toString() ?? '');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.courseCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(isTopup ? Icons.add_circle_outline : Icons.shopping_cart_outlined,
              color: isTopup ? AppColors.success : AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_txLabel(tx),
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(formatArabicDate(date), style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          Text('${isTopup ? '+' : '-'}${formatAmount(tx['amount'])}',
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isTopup ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }

  Widget _purchaseRow(UserDetailController ctrl, Map<String, dynamic> p) {
    final date = DateTime.tryParse(p['created_at']?.toString() ?? '');
    final isGrant = double.tryParse('${p['price_paid']}') == 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.courseCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(isGrant ? Icons.card_giftcard_outlined : Icons.menu_book_rounded,
              color: isGrant ? AppColors.success : AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                          p['course_name'] ?? p['description'] ?? 'دورة',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isGrant) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('منحة',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ),
                    ],
                  ],
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(formatArabicDate(date), style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatAmount(p['price_paid'] ?? p['amount']),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              if (isGrant)
                InkWell(
                  onTap: ctrl.busy.value
                      ? null
                      : () =>
                          ctrl.revokeGrant((p['course_id'] as num).toInt()),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 2),
                        Text('إلغاء المنحة',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payoutRow(Map<String, dynamic> p) {
    final date = DateTime.tryParse(p['created_at']?.toString() ?? '');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.courseCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p['note'] != null && '${p['note']}'.isNotEmpty)
                  Text('${p['note']}',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14))
                else
                  Text('دفعة للمعلم', style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(formatArabicDate(date), style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          Text(formatAmount(p['amount']),
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _teacherCourseRow(Map<String, dynamic> c) {
    final buyers = ((c['purchases_count'] ?? 0) as num).toInt();
    final percent = double.tryParse('${c['teacher_percent'] ?? 0}') ?? 0;
    final percentLabel =
        percent == percent.roundToDouble() ? percent.toInt() : percent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.courseCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_lesson_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(c['name'] ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(formatAmount(c['price']),
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          if (c['teacher_id'] != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text('$buyers مشتري — حصة المعلم $percentLabel%',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}
