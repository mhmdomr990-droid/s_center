import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/course_card.dart';
import '../../../widgets/gradient_app_bar.dart';
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
          appBar: const GradientAppBar(title: 'الدورات'),
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
                        _buildFilterChip(
                          ctrl,
                          'الكل',
                          ctrl.selectedSpecializationId.value == null,
                          () => ctrl.selectSpecialization(null),
                        ),
                        ...ctrl.specializations.map((spec) => _buildFilterChip(
                              ctrl,
                              spec.name,
                              ctrl.selectedSpecializationId.value == spec.id,
                              () => ctrl.selectSpecialization(spec.id),
                            )),
                      ],
                    )),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: Obx(() => ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildYearChip(
                          ctrl,
                          'كل السنوات',
                          ctrl.selectedYear.value == null,
                          () => ctrl.selectYear(null),
                        ),
                        ...CoursesController.availableYears.map((year) => _buildYearChip(
                              ctrl,
                              'السنة $year',
                              ctrl.selectedYear.value == year,
                              () => ctrl.selectYear(year),
                            )),
                      ],
                    )),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() => Text(
                                ctrl.filterTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Obx(() => Text(
                              '${ctrl.courses.length} دورة',
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Obx(() {
                      if (ctrl.courses.isEmpty) {
                        return const EmptyState(
                          icon: Icons.school_outlined,
                          title: 'لا توجد دورات مطابقة',
                          subtitle: 'جرّب اختيار اختصاص أو سنة أخرى',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: ctrl.courses.length,
                        itemBuilder: (context, index) {
                          final course = ctrl.courses[index];
                          return CourseCard(
                            courseId: course.id,
                            name: course.name,
                            teacherName: course.teacherName,
                            price: course.price,
                            specialization: course.specializationName,
                            specializationId: course.specializationId,
                            year: course.year,
                            onTap: () => Get.toNamed(AppRoutes.courseDetail,
                                arguments: {'courseId': course.id, 'course': course}),
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

  Widget _buildFilterChip(
      CoursesController ctrl, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildYearChip(
      CoursesController ctrl, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primaryLight : AppColors.divider),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          )),
        ),
      ),
    );
  }
}
