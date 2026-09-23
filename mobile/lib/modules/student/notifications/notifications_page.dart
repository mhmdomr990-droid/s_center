import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import '../../../data/models/notification_model.dart';
import 'notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  (IconData, Color) _notifStyle(NotificationModel notif) {
    final text = '${notif.title} ${notif.body}'.toLowerCase();
    if (text.contains('purchase') || text.contains('شراء')) {
      return (Icons.shopping_bag_rounded, AppColors.primary);
    }
    if (text.contains('topup') ||
        text.contains('wallet') ||
        text.contains('شحن') ||
        text.contains('رصيد')) {
      return (Icons.account_balance_wallet_rounded, AppColors.success);
    }
    if (text.contains('device') || text.contains('جهاز')) {
      return (Icons.phonelink_lock_rounded, AppColors.warning);
    }
    if (text.contains('welcome') || text.contains('مرحبا')) {
      return (Icons.celebration_rounded, const Color(0xFF6A1B9A));
    }
    return (Icons.notifications_rounded, AppColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      init: NotificationsController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            title: 'الإشعارات',
            actions: [
              Obx(() {
                if (ctrl.unreadCount.value == 0) return const SizedBox();
                return TextButton(
                  onPressed: ctrl.markAllAsRead,
                  child: const Text('قراءة الكل', style: TextStyle(color: Colors.white)),
                );
              }),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            if (ctrl.notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none,
                title: 'لا توجد إشعارات',
                subtitle: 'ستظهر الإشعارات الجديدة هنا',
              );
            }

            return RefreshIndicator(
              onRefresh: ctrl.loadNotifications,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: ctrl.notifications.length,
                itemBuilder: (context, index) {
                          final notif = ctrl.notifications[index];
                          final (notifIcon, notifColor) = _notifStyle(notif);
                  return GestureDetector(
                    onTap: () {
                      if (!notif.isRead) ctrl.markAsRead(notif.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: notif.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notif.isRead ? AppColors.divider.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? notifColor.withValues(alpha: 0.08)
                                  : notifColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              notifIcon,
                              color: notif.isRead
                                  ? notifColor.withValues(alpha: 0.5)
                                  : notifColor,
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
                                    Expanded(
                                      child: Text(notif.title, style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                                      )),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(notif.body, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(ctrl.formatDate(notif.createdAt), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }
}
