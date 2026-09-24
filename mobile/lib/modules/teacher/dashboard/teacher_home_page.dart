import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../data/models/course_model.dart';
import 'teacher_home_controller.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TeacherHomeController>(
      init: TeacherHomeController(),
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            centerTitle: false,
            titleWidget: Obx(() => Text(
                  ctrl.userName.value.isEmpty
                      ? 'مرحباً أستاذ 👋'
                      : 'مرحباً أستاذ ${ctrl.userName.value} 👋',
                  style:
                      GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 17),
                )),
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            return RefreshIndicator(
              onRefresh: ctrl.loadDashboard,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إحصائياتي', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatItem('المشتريات', '${ctrl.totalPurchases.value}'),
                            const SizedBox(width: 16),
                            _buildStatItem('الأرباح', '${ctrl.totalEarned.value} SYP'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatItem('المدفوع', '${ctrl.totalPaid.value} SYP'),
                            const SizedBox(width: 16),
                            _buildStatItem('المتبقّي', '${ctrl.remaining.value} SYP'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [7, 30, 90].map((days) {
                      final isSelected = ctrl.selectedDays.value == days;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ctrl.selectedDays.value = days;
                            ctrl.loadDashboard();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.courseCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
                            ),
                            child: Center(
                              child: Text('$days يوم', style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('دوراتي', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  if (ctrl.courses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text('لا توجد دورات', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
                    )
                  else
                    ...ctrl.courses.map((course) => GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.teacherCourseDetail, arguments: {'courseId': course.id}),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.courseCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.school, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.name, style: AppTextStyles.titleMedium.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(_courseMetaLine(course), style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('${course.purchasesCount ?? 0} مشتري', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            Text('${course.price} SYP', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  String _courseMetaLine(CourseModel course) {
    final spec = course.specializationName;
    final year = course.year > 0 ? 'السنة ${course.year}' : '';
    if (spec.isEmpty) return year;
    if (year.isEmpty) return spec;
    return '$spec — $year';
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
