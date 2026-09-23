import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/course_card.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/section_header.dart';
import '../../../modules/student/notifications/notifications_controller.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _refreshUnread() async {
    if (Get.isRegistered<NotificationsController>()) {
      await Get.find<NotificationsController>().loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            centerTitle: false,
            titleWidget: Obx(() => Text(
                  ctrl.userName.value.isEmpty
                      ? 'مرحباً 👋'
                      : 'مرحباً، ${ctrl.userName.value} 👋',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 17),
                )),
            actions: [
              Obx(() {
                int count = 0;
                if (Get.isRegistered<NotificationsController>()) {
                  count = Get.find<NotificationsController>().unreadCount.value;
                }
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white, size: 26),
                      onPressed: () {
                        if (Get.isRegistered<NotificationsController>()) {
                          Get.find<NotificationsController>().onTabOpened();
                        }
                        Get.toNamed(AppRoutes.notifications);
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(width: 4),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) {
              return const LoadingListShimmer();
            }

            return RefreshIndicator(
              onRefresh: () async {
                await ctrl.loadData();
                await _refreshUnread();
              },
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  BalanceCard(
                    balance: ctrl.balance.value,
                    onTopup: () => Get.toNamed(AppRoutes.wallet),
                  ),
                  const SizedBox(height: 24),
                  if (ctrl.myCourses.isNotEmpty) ...[
                    const SectionHeader(
                      title: 'دوراتي المشتراة',
                      icon: Icons.workspace_premium_rounded,
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: ctrl.myCourses.map((course) {
                            return GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.courseDetail,
                                  arguments: {'courseId': course.courseId}),
                              child: Container(
                                width: 180,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: AppShadows.soft,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('مشتراة',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(course.courseName,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(fontWeight: FontWeight.w600),
                                        softWrap: true),
                                    if (course.specializationName != null ||
                                        course.year != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        [
                                          if (course.specializationName !=
                                                  null &&
                                              course.specializationName!
                                                  .isNotEmpty)
                                            course.specializationName!,
                                          if (course.year != null)
                                            'السنة ${course.year}',
                                        ].join(' • '),
                                        style:
                                            AppTextStyles.caption.copyWith(fontSize: 11),
                                        softWrap: true,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(course.pricePaid,
                                            style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        const Text('SYP',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'أحدث الدورات',
                    icon: Icons.fiber_new_rounded,
                    actionLabel: 'عرض الكل',
                    onAction: () => Get.toNamed(AppRoutes.courses),
                  ),
                  const SizedBox(height: 8),
                  ...ctrl.latestCourses.map((course) => CourseCard(
                        courseId: course.id,
                        name: course.name,
                        teacherName: course.teacherName,
                        price: course.price,
                        specialization: course.specializationName,
                        specializationId: course.specializationId,
                        year: course.year,
                        onTap: () => Get.toNamed(AppRoutes.courseDetail,
                            arguments: {'courseId': course.id, 'course': course}),
                      )),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
