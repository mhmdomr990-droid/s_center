import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/course_card.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import 'courses_controller.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CoursesController>(
      init: CoursesController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('الدورات')),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            return RefreshIndicator(
              onRefresh: ctrl.loadCatalog,
              color: AppColors.primary,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: Obx(() => ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildFilterChip(ctrl, 'الكل', null),
                        ...ctrl.specializations.map((spec) => _buildFilterChip(ctrl, spec.name, spec.id)),
                      ],
                    )),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Obx(() {
                      if (ctrl.courses.isEmpty) {
                        return const EmptyState(icon: Icons.school_outlined, title: 'لا توجد دورات', subtitle: 'لم تُنشر أي دورات بعد');
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: ctrl.courses.length,
                        itemBuilder: (context, index) {
                          final course = ctrl.courses[index];
                          return CourseCard(
                            name: course.name,
                            teacherName: course.teacherName,
                            price: course.price,
                            specialization: course.specializationName,
                            year: course.year,
                            onTap: () => Get.toNamed(AppRoutes.courseDetail, arguments: {'courseId': course.id}),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFilterChip(CoursesController ctrl, String label, int? specId) {
    final isSelected = ctrl.selectedSpecializationId.value == specId;
    return GestureDetector(
      onTap: () => ctrl.filterBySpecialization(specId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          )),
        ),
      ),
    );
  }
}
