import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/download_lecture_button.dart';
import '../../../widgets/lecture_tile.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/section_header.dart';
import '../../../utils/format.dart';
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
            Text('هل تريد فعلاً شراء "${course.name}" مقابل ${formatAmount(course.price)} SYP؟'),
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

  bool _isNewLecture(DateTime? createdAt) {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt).inDays < 7;
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
          appBar: const GradientAppBar(title: 'تفاصيل الدورة'),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.courseCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Obx(() {
                final course = initialCourse ?? ctrl.currentCourse.value;
                final bought = ctrl.isPurchased(courseId) ||
                    (course?.isPurchased ?? false);
                if (bought) {
                  return CustomButton(
                    text: '✔ لقد اشتريت هذه الدورة',
                    backgroundColor: const Color(0xFF43A047),
                    onPressed: null,
                    icon: Icons.check_circle_outline,
                  );
                }
                return CustomButton(
                  text: ctrl.isPurchasing.value
                      ? 'جاري الشراء...'
                      : 'شراء الدورة${course != null ? ' - ${formatAmount(course.price)} SYP' : ''}',
                  isLoading: ctrl.isPurchasing.value,
                  onPressed: () {
                    if (course == null) return;
                    _confirmPurchase(context, ctrl, course);
                  },
                  icon: Icons.shopping_cart_outlined,
                );
              }),
            ),
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
                    boxShadow: AppShadows.colored,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -30,
                        top: -40,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: 'course-icon-$courseId',
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.school,
                                      color: Colors.white, size: 26),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(course.specializationName,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Hero(
                            tag: 'course-title-$courseId',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(course.name,
                                  style: GoogleFonts.cairo(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                          if (course.teacherName != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Text(course.teacherName!,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Hero(
                            tag: 'course-price-$courseId',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(formatAmount(course.price),
                                      style: GoogleFonts.cairo(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  const SizedBox(width: 6),
                                  const Text('SYP',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (course.description != null && course.description!.isNotEmpty) ...[
                  const SectionHeader(
                    title: 'الوصف',
                    icon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(course.description!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary, height: 1.6)),
                  ),
                  const SizedBox(height: 20),
                ],
                Obx(() {
                  if (ctrl.isLoadingDetail.value &&
                      ctrl.lectures.isEmpty &&
                      ctrl.detailError.value == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }
                  return SectionHeader(
                    title: 'المحاضرات (${ctrl.lectures.length})',
                    icon: Icons.play_lesson_rounded,
                  );
                }),
                const SizedBox(height: 8),
                if (ctrl.detailError.value != null && ctrl.lectures.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(ctrl.detailError.value!,
                            style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              ctrl.loadCourseDetail(courseId, course: initialCourse),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                else if (ctrl.lectures.isEmpty && !ctrl.isLoadingDetail.value)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد محاضرات بعد',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...ctrl.lectures.asMap().entries.map((entry) {
                    final lecture = entry.value;
                    final canDownload = lecture.isVideo &&
                        (ctrl.isPurchased(courseId) || course.isPurchased);
                    return LectureTile(
                      index: entry.key + 1,
                      title: lecture.title,
                      type: lecture.type,
                      isNew: _isNewLecture(lecture.createdAt),
                      trailing: lecture.isVideo
                          ? DownloadLectureButton(
                              lectureId: lecture.id,
                              enabled: canDownload,
                            )
                          : null,
                      onTap: () => Get.toNamed(AppRoutes.lectureView, arguments: {
                        'lecture': lecture,
                        'lectures': ctrl.lectures,
                        'currentIndex': entry.key,
                      }),
                    );
                  }),
                const SizedBox(height: 90),
              ],
            );
          }),
        );
      },
    );
  }
}
