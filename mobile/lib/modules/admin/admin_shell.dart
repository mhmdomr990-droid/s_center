import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_controller.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/providers/api_client.dart';
import 'account/admin_account_page.dart';
import 'content/content_page.dart';
import 'notifications/send_notification_page.dart';
import 'teachers/teachers_page.dart';
import 'topups/topup_requests_page.dart';
import 'users/users_page.dart';

// متحكّم تبويب الأدمن — الشارة (عدد طلبات الشحن المعلّقة) وتحديثها
class AdminShellController extends GetxController {
  final pendingTopups = 0.obs;
  final AdminProvider _provider = AdminProvider(Get.find<ApiClient>());

  @override
  void onInit() {
    super.onInit();
    loadBadges();
  }

  Future<void> loadBadges() async {
    try {
      final response = await _provider.badges();
      final data = response.data['data'];
      pendingTopups.value = (data['pending_topups'] ?? 0) as int;
    } catch (_) {
      // الشارة اختيارية — الفشل لا يمنع الاستخدام
    }
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = 0.obs;
    Get.put(AdminShellController(), permanent: false);

    return Obx(() {
      final _ = Get.find<ThemeController>().themeMode.value;
      final pages = [
        TopupRequestsPage(),
        UsersPage(),
        ContentPage(),
        TeachersPage(),
        SendNotificationPage(),
        AdminAccountPage(),
      ];
      return Scaffold(
        body: IndexedStack(
          index: currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.bottomNavBg,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, -4)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(currentIndex, 0, Icons.payments_outlined, 'الطلبات',
                      badgeCount: Get.isRegistered<AdminShellController>()
                          ? Get.find<AdminShellController>().pendingTopups.value
                          : 0),
                  _buildNavItem(currentIndex, 1, Icons.group_outlined, 'المستخدمون'),
                  _buildNavItem(currentIndex, 2, Icons.menu_book_outlined, 'المحتوى'),
                  _buildNavItem(currentIndex, 3, Icons.school_outlined, 'المدرسون'),
                  _buildNavItem(currentIndex, 4, Icons.notifications_active_outlined, 'الإشعارات'),
                  _buildNavItem(currentIndex, 5, Icons.person_rounded, 'حسابي'),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(RxInt currentIndex, int index, IconData icon, String label,
      {int badgeCount = 0}) {
    final isSelected = currentIndex.value == index;
    return GestureDetector(
      onTap: () => currentIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bottomNavPill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    color: isSelected ? AppColors.bottomNavSelected : AppColors.bottomNavUnselected,
                    size: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: isSelected ? AppColors.bottomNavSelected : AppColors.bottomNavUnselected,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
