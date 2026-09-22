import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme/app_colors.dart';
import '../modules/student/home/home_page.dart';
import '../modules/student/courses/courses_page.dart';
import '../modules/student/notifications/notifications_page.dart';
import '../modules/student/wallet/wallet_page.dart';
import '../modules/teacher/dashboard/teacher_home_page.dart';
import '../modules/teacher/courses/teacher_courses_page.dart';
import '../modules/teacher/earnings/earnings_page.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    final currentIndex = 0.obs;

    final pages = [
      const HomePage(),
      const CoursesPage(),
      const NotificationsPage(),
      const WalletPage(),
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
                _buildNavItem(currentIndex, 2, Icons.notifications_rounded, 'الإشعارات'),
                _buildNavItem(currentIndex, 3, Icons.account_balance_wallet_rounded, 'المحفظة'),
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
