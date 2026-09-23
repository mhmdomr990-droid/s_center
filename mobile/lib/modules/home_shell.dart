import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme/app_colors.dart';
import '../modules/student/home/home_page.dart';
import '../modules/student/courses/courses_page.dart';
import '../modules/student/notifications/notifications_page.dart';
import '../modules/student/notifications/notifications_controller.dart';
import '../modules/student/profile/profile_page.dart';
import '../modules/student/wallet/wallet_page.dart';
import '../modules/teacher/dashboard/teacher_home_page.dart';
import '../modules/teacher/courses/teacher_courses_page.dart';
import '../modules/teacher/earnings/earnings_page.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = 0.obs;
    Get.put(NotificationsController(), permanent: false);

    final pages = [
      const HomePage(),
      const CoursesPage(),
      const NotificationsPage(),
      const WalletPage(),
      const ProfilePage(),
    ];

    return Obx(() => Scaffold(
      body: IndexedStack(
        index: currentIndex.value,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(currentIndex, 0, Icons.home_rounded, 'الرئيسية'),
                _buildNavItem(currentIndex, 1, Icons.school_rounded, 'الدورات'),
                _buildNavItem(
                  currentIndex,
                  2,
                  Icons.notifications_rounded,
                  'الإشعارات',
                  badgeCount: _unreadCount(),
                  onTap: () {
                    if (Get.isRegistered<NotificationsController>()) {
                      Get.find<NotificationsController>().onTabOpened();
                    }
                  },
                ),
                _buildNavItem(currentIndex, 3, Icons.account_balance_wallet_rounded, 'المحفظة'),
                _buildNavItem(currentIndex, 4, Icons.person_rounded, 'حسابي'),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  int _unreadCount() {
    if (Get.isRegistered<NotificationsController>()) {
      return Get.find<NotificationsController>().unreadCount.value;
    }
    return 0;
  }

  Widget _buildNavItem(RxInt currentIndex, int index, IconData icon, String label,
      {int badgeCount = 0, VoidCallback? onTap}) {
    final isSelected = currentIndex.value == index;
    return GestureDetector(
      onTap: () {
        currentIndex.value = index;
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isSelected ? AppColors.primary : AppColors.textHint, size: 26),
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
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textHint,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = 0.obs;

    final pages = [
      const TeacherHomePage(),
      const TeacherCoursesPage(),
      const EarningsPage(),
    ];

    return Obx(() => Scaffold(
      body: IndexedStack(
        index: currentIndex.value,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(currentIndex, 0, Icons.dashboard_rounded, 'لوحة التحكم'),
                _buildNavItem(currentIndex, 1, Icons.school_rounded, 'الدورات'),
                _buildNavItem(currentIndex, 2, Icons.account_balance_rounded, 'الأرباح'),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildNavItem(RxInt currentIndex, int index, IconData icon, String label) {
    final isSelected = currentIndex.value == index;
    return GestureDetector(
      onTap: () => currentIndex.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textHint, size: 26),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textHint,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
