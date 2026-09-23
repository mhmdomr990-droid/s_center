import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'teacher_courses_controller.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherCoursesController>(
      init: TeacherCoursesController(),
      initState: (_) {
        Get.find<TeacherCoursesController>().loadCourses();
      },
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'دوراتي'),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            if (ctrl.courses.isEmpty) {
              return const EmptyState(icon: Icons.school_outlined, title: 'لا توجد دورات', subtitle: 'لم يتم تعيين أي دورة لك بعد');
            }

            return RefreshIndicator(
              onRefresh: ctrl.loadCourses,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: ctrl.courses.length,
                itemBuilder: (context, index) {
                  final course = ctrl.courses[index];
                  return GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.teacherCourseDetail, arguments: {'courseId': course.id}),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.courseCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school, color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('السنة ${course.year} | ${course.purchasesCount ?? 0} مشتري', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textHint),
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
