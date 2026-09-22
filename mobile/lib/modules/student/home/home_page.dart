import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/balance_card.dart';
import '../../../widgets/course_card.dart';
import '../../../widgets/loading_shimmer.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('الرئيسية', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) {
              return const LoadingListShimmer();
            }

            return RefreshIndicator(
              onRefresh: ctrl.loadData,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('دوراتي المشتراة', style: AppTextStyles.titleLarge),
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
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('مشتراة',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(course.courseName,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(fontWeight: FontWeight.w600),
                                        softWrap: true),
                                    if (course.specializationName != null || course.year != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        [
                                          if (course.specializationName != null &&
                                              course.specializationName!.isNotEmpty)
                                            course.specializationName!,
                                          if (course.year != null) 'السنة ${course.year}',
                                        ].join(' • '),
                                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                                        softWrap: true,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text('${course.pricePaid} SYP',
                                        style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('أحدث الدورات', style: AppTextStyles.titleLarge),
                  ),
                  const SizedBox(height: 8),
                  ...ctrl.latestCourses.map((course) => CourseCard(
                    name: course.name,
                    teacherName: course.teacherName,
                    price: course.price,
                    specialization: course.specializationName,
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
