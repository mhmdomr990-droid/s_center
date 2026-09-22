import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import 'notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      init: NotificationsController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('الإشعارات'),
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
                              color: notif.isRead ? AppColors.textHint.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                              color: notif.isRead ? AppColors.textHint : AppColors.primary,
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
