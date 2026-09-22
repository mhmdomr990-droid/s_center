import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/lecture_tile.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../data/models/course_model.dart';
import 'courses_controller.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({super.key});

  void _confirmPurchase(BuildContext context, CoursesController ctrl, CourseModel course) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('تأكيد الشراء'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل تريد فعلاً شراء "${course.name}" مقابل ${course.price} SYP؟'),
            const SizedBox(height: 12),
            const Text(
              'لا يمكن التراجع عن العملية بعد التأكيد.',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Get.back();
              ctrl.purchaseCourse(course.id);
            },
            child: const Text('تأكيد الشراء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final courseId = args['courseId'] as int;
    final initialCourse = args['course'] as CourseModel?;

    return GetBuilder<CoursesController>(
      init: CoursesController(),
      initState: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<CoursesController>().loadCourseDetail(courseId, course: initialCourse);
        });
      },
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('تفاصيل الدورة'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Obx(() {
            final course = initialCourse ?? ctrl.currentCourse.value;

            if (course == null) {
              if (ctrl.isLoadingDetail.value) return const LoadingListShimmer();
              return const Center(child: Text('الدورة غير موجودة'));
            }

            return ListView(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(course.specializationName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                      Text(course.name, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (course.teacherName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Text(course.teacherName!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text('${course.price} SYP', style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (course.description != null && course.description!.isNotEmpty) ...[
                  Text('الوصف', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Text(course.description!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                ],
                Obx(() {
                  if (ctrl.isPurchased(courseId) || course.isPurchased) {
                    return CustomButton(
                      text: '✔ لقد اشتريت هذه الدورة',
                      backgroundColor: const Color(0xFF43A047),
                      onPressed: null,
                      icon: Icons.check_circle_outline,
                    );
                  }
                  return CustomButton(
                    text: ctrl.isPurchasing.value ? 'جاري الشراء...' : 'شراء الدورة - ${course.price} SYP',
                    isLoading: ctrl.isPurchasing.value,
                    onPressed: () => _confirmPurchase(context, ctrl, course),
                    icon: Icons.shopping_cart_outlined,
                  );
                }),
                const SizedBox(height: 24),
                Obx(() {
                  if (ctrl.isLoadingDetail.value && ctrl.lectures.isEmpty && ctrl.detailError.value == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }
                  return Text('المحاضرات (${ctrl.lectures.length})', style: AppTextStyles.titleLarge);
                }),
                const SizedBox(height: 8),
                if (ctrl.detailError.value != null && ctrl.lectures.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(ctrl.detailError.value!, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ctrl.loadCourseDetail(courseId, course: initialCourse),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                else if (ctrl.lectures.isEmpty && !ctrl.isLoadingDetail.value)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد محاضرات بعد', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...ctrl.lectures.asMap().entries.map((entry) {
                    final lecture = entry.value;
                    return LectureTile(
                      index: entry.key + 1,
                      title: lecture.title,
                      type: lecture.type,
                      onTap: () => Get.toNamed(AppRoutes.lectureView, arguments: {
                        'lecture': lecture,
                        'lectures': ctrl.lectures,
                        'currentIndex': entry.key,
                      }),
                    );
                  }),
              ],
            );
          }),
        );
      },
    );
  }
}
