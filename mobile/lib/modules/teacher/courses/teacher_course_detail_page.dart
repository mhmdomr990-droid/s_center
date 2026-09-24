import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../../../widgets/lecture_tile.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/gradient_app_bar.dart';
import 'teacher_courses_controller.dart';

class TeacherCourseDetailPage extends StatelessWidget {
  const TeacherCourseDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final courseId = args['courseId'] as int;

    return GetBuilder<TeacherCoursesController>(
      init: TeacherCoursesController(),
      initState: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<TeacherCoursesController>()) {
            Get.find<TeacherCoursesController>().loadCourseDetail(courseId);
          }
        });
      },
      builder: (ctrl) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(
            title: 'تفاصيل الدورة',
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Get.toNamed(AppRoutes.addLecture, arguments: {'courseId': courseId}),
              ),
            ],
          ),
          body: Obx(() {
            if (ctrl.isLoading.value) return const LoadingListShimmer();

            final course = ctrl.currentCourse.value;
            if (course == null) return const Center(child: Text('الدورة غير موجودة'));

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
                      Text(course.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (course.specializationName.isNotEmpty) ...[
                            _buildInfoChip(course.specializationName),
                            const SizedBox(width: 8),
                          ],
                          _buildInfoChip('${course.purchasesCount ?? 0} مشتري'),
                          const SizedBox(width: 8),
                          _buildInfoChip('${course.price} SYP'),
                          if (course.year > 0) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip('السنة ${course.year}'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('المحاضرات (${ctrl.lectures.length})', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                if (ctrl.lectures.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('لا توجد محاضرات. اضغط + للإضافة', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
                  )
                else
                  ...ctrl.lectures.map((lecture) => LectureTile(
                    index: ctrl.lectures.indexOf(lecture) + 1,
                    title: lecture.title,
                    type: lecture.type,
                    isPublished: lecture.isPublished,
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(lecture.isPublished ? 'إخفاء' : 'إظهار'),
                        ),
                        PopupMenuItem(value: 'delete', child: const Text('حذف', style: TextStyle(color: Colors.red))),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          Get.toNamed(AppRoutes.addLecture,
                              arguments: {'courseId': courseId, 'lecture': lecture});
                        } else if (value == 'toggle') {
                          ctrl.togglePublished(lecture.id, !lecture.isPublished, courseId);
                        } else if (value == 'delete') {
                          _confirmDelete(ctrl, lecture.id, courseId);
                        }
                      },
                    ),
                  )),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _confirmDelete(TeacherCoursesController ctrl, int lectureId, int courseId) {
    Get.defaultDialog(
      title: 'حذف المحاضرة',
      middleText: 'هل أنت متأكد من حذف هذه المحاضرة؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        ctrl.deleteLecture(lectureId, courseId);
      },
    );
  }
}
