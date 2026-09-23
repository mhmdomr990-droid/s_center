import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import '../../../utils/format.dart';

class NotificationsController extends GetxController {
  final NotificationProvider _notificationProvider;

  NotificationsController() : _notificationProvider = NotificationProvider(Get.find<ApiClient>());

  final isLoading = true.obs;
  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> onTabOpened() async {
    await loadNotifications();
    if (unreadCount.value > 0) {
      await markAllAsRead();
    }
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final response = await _notificationProvider.getNotifications(limit: 50);
      final data = response.data['data'];
      if (data is Map) {
        final items = data['items'];
        if (items is List) {
          notifications.value = items.map<NotificationModel>((e) => NotificationModel.fromJson(e)).toList();
        }
        unreadCount.value = (data['unread_count'] as num?)?.toInt() ??
            notifications.where((n) => !n.isRead).length;
      } else if (data is List) {
        notifications.value = data.map<NotificationModel>((e) => NotificationModel.fromJson(e)).toList();
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _notificationProvider.markAsRead(id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index] = NotificationModel(
          id: notifications[index].id,
          title: notifications[index].title,
          body: notifications[index].body,
          isRead: true,
          createdAt: notifications[index].createdAt,
        );
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationProvider.markAllAsRead();
      for (var i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = NotificationModel(
            id: notifications[i].id,
            title: notifications[i].title,
            body: notifications[i].body,
            isRead: true,
            createdAt: notifications[i].createdAt,
          );
        }
      }
      unreadCount.value = 0;
    } catch (_) {}
  }

  String formatDate(DateTime? date) => formatArabicDate(date);
}
