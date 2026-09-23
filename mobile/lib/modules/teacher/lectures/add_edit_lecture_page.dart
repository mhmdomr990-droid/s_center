import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../courses/teacher_courses_controller.dart';

class AddEditLecturePage extends StatelessWidget {
  const AddEditLecturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final courseId = args['courseId'] as int;

    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final selectedType = 'VIDEO'.obs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'إضافة محاضرة'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              labelText: 'عنوان المحاضرة',
              prefixIcon: Icons.title,
              controller: titleCtrl,
            ),
            const SizedBox(height: 16),
            Text('نوع المحاضرة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Obx(() => Row(
              children: [
                _buildTypeChip(selectedType, 'VIDEO', 'فيديو', Icons.videocam),
                const SizedBox(width: 8),
                _buildTypeChip(selectedType, 'PDF', 'PDF', Icons.picture_as_pdf),
                const SizedBox(width: 8),
                _buildTypeChip(selectedType, 'TEXT', 'نص', Icons.article),
              ],
            )),
            const SizedBox(height: 16),
            Obx(() {
              if (selectedType.value == 'VIDEO' || selectedType.value == 'PDF') {
                return CustomTextField(
                  labelText: selectedType.value == 'VIDEO' ? 'رابط الفيديو' : 'رابط PDF',
                  prefixIcon: Icons.link,
                  controller: urlCtrl,
                );
              }
              return const SizedBox();
            }),
            const SizedBox(height: 16),
            Obx(() {
              if (selectedType.value == 'TEXT') {
                return CustomTextField(
                  labelText: 'المحتوى النصي',
                  prefixIcon: Icons.article_outlined,
                  controller: contentCtrl,
                  maxLines: 10,
                );
              }
              return const SizedBox();
            }),
            const SizedBox(height: 24),
            GetBuilder<TeacherCoursesController>(
              builder: (ctrl) {
                return Obx(() => CustomButton(
                  text: 'إضافة المحاضرة',
                  isLoading: ctrl.isSaving.value,
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) {
                      Get.snackbar('خطأ', 'أدخل عنوان المحاضرة', backgroundColor: AppColors.error, colorText: Colors.white);
                      return;
                    }
                    ctrl.createLecture(
                      courseId,
                      title: titleCtrl.text.trim(),
                      type: selectedType.value,
                      url: urlCtrl.text.isNotEmpty ? urlCtrl.text.trim() : null,
                      content: contentCtrl.text.isNotEmpty ? contentCtrl.text.trim() : null,
                    );
                  },
                  icon: Icons.add,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(RxString selected, String value, String label, IconData icon) {
    final isSelected = selected.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => selected.value = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
