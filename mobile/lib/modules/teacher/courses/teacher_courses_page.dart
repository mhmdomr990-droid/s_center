import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/status_pill.dart';
import '../../../data/models/course_model.dart';
import 'teacher_courses_controller.dart';

class TeacherCoursesPage extends StatelessWidget {
  const TeacherCoursesPage({super.key});

  String _metaLine(CourseModel course) {
    final spec = course.specializationName;
    final year = course.year > 0 ? 'السنة ${course.year}' : '';
    final parts = <String>[
      if (spec.isNotEmpty) spec,
      if (year.isNotEmpty) year,
      '${course.purchasesCount ?? 0} مشتري',
    ];
    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherCoursesController>(
      init: TeacherCoursesController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GradientAppBar(title: 'دوراتي'),
          body: Obx(() {
            if (ctrl.isLoading.value && ctrl.courses.isEmpty) {
              return const LoadingListShimmer();
            }

            return RefreshIndicator(
              onRefresh: ctrl.loadCourses,
              color: AppColors.primary,
              child: Column(
                children: [
                  Container(
                    color: AppColors.sectionStrip,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 42,
                          child: Obx(() => ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              _buildFilterChip(
                                'الكل',
                                ctrl.selectedSpecializationId.value == null,
                                () => ctrl.selectSpecialization(null),
                              ),
                              ...ctrl.specializations.map((spec) => _buildFilterChip(
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
                                'كل السنوات',
                                ctrl.selectedYear.value == null,
                                () => ctrl.selectYear(null),
                              ),
                              ...TeacherCoursesController.availableYears
                                  .map((year) => _buildYearChip(
                                        'السنة $year',
                                        ctrl.selectedYear.value == year,
                                        () => ctrl.selectYear(year),
                                      )),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Obx(() => Text(
                                ctrl.filterTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        Obx(() => Text(
                              '${ctrl.filteredCourses.length} دورة',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textHint),
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
                          title: 'لا توجد دورات',
                          subtitle: 'لم يتم تعيين أي دورة لك بعد',
                        );
                      }
                      final filtered = ctrl.filteredCourses;
                      if (filtered.isEmpty) {
                        return const EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'لا توجد دورات مطابقة',
                          subtitle: 'جرّب اختيار اختصاص أو سنة أخرى',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final course = filtered[index];
                          return GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.teacherCourseDetail,
                                arguments: {'courseId': course.id}),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.courseCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.school,
                                        color: AppColors.primary, size: 26),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(course.name,
                                            style: AppTextStyles.titleMedium
                                                .copyWith(fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(_metaLine(course),
                                            style: AppTextStyles.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            StatusPill(
                                              label: course.isPublished
                                                  ? 'منشور'
                                                  : 'مخفي',
                                              color: course.isPublished
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'أرباح ${course.earned ?? '0.00'} SYP',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_back_ios_new,
                                      size: 16, color: AppColors.textHint),
                                ],
                              ),
                            ),
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  Widget _buildYearChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? AppColors.primaryLight
                  : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              )),
        ),
      ),
    );
  }
}
