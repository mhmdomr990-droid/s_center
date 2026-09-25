import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/lecture_model.dart';
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
    final lecture = args['lecture'] as LectureModel?;
    final isEdit = lecture != null;

    final titleCtrl = TextEditingController(text: lecture?.title ?? '');
    final urlCtrl = TextEditingController(text: lecture?.url ?? '');
    final contentCtrl = TextEditingController(text: lecture?.content ?? '');
    final sortCtrl = TextEditingController(text: (lecture?.sortOrder ?? 0).toString());
    final selectedType = (lecture?.type ?? 'VIDEO').obs;

    final selectedVideoPath = Rxn<String>();
    final selectedVideoSize = 0.0.obs;

    const allowedVideoExts = ['mp4', 'webm', 'mov', 'mkv'];
    const maxVideoBytes = 2048 * 1024 * 1024;

    Future<void> pickVideo() async {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      final file = result?.files.single;
      final path = file?.path;
      if (file == null || path == null) return;
      final ext = path.split('.').last.toLowerCase();
      if (!allowedVideoExts.contains(ext)) {
        Get.snackbar('خطأ', 'الصيغ المسموحة: mp4، webm، mov، mkv',
            backgroundColor: AppColors.error, colorText: Colors.white);
        return;
      }
      if (file.size > maxVideoBytes) {
        Get.snackbar('خطأ', 'حجم الملف يتجاوز الحد الأقصى 2048MB',
            backgroundColor: AppColors.error, colorText: Colors.white);
        return;
      }
      selectedVideoPath.value = path;
      selectedVideoSize.value = file.size.toDouble();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: isEdit ? 'تعديل محاضرة' : 'إضافة محاضرة'),
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
            Text('نوع المحاضرة', style: AppTextStyles.titleMedium),
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
              if (selectedType.value == 'VIDEO') {
                return _buildVideoPicker(
                  selectedPath: selectedVideoPath,
                  selectedSize: selectedVideoSize,
                  lecture: lecture,
                  onPick: pickVideo,
                );
              }
              if (selectedType.value == 'PDF') {
                return CustomTextField(
                  labelText: 'رابط PDF',
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
            const SizedBox(height: 16),
            CustomTextField(
              labelText: 'الترتيب (رقمي)',
              prefixIcon: Icons.sort,
              controller: sortCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            GetBuilder<TeacherCoursesController>(
              builder: (ctrl) {
                return Obx(() {
                  final uploading = ctrl.uploadProgress.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (uploading > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: uploading,
                            minHeight: 8,
                            backgroundColor: AppColors.courseCard,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جاري الرفع... ${(uploading * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomButton(
                        text: isEdit ? 'حفظ التغييرات' : 'إضافة المحاضرة',
                        isLoading: ctrl.isSaving.value,
                        onPressed: () {
                          if (titleCtrl.text.isEmpty) {
                            Get.snackbar('خطأ', 'أدخل عنوان المحاضرة', backgroundColor: AppColors.error, colorText: Colors.white);
                            return;
                          }
                          final sortOrder = int.tryParse(sortCtrl.text.trim());
                          if (selectedType.value == 'PDF') {
                            if (urlCtrl.text.isEmpty) {
                              Get.snackbar('خطأ', 'أدخل رابط PDF', backgroundColor: AppColors.error, colorText: Colors.white);
                              return;
                            }
                          }
                          if (selectedType.value == 'VIDEO') {
                            if (selectedVideoPath.value == null) {
                              if (!isEdit) {
                                Get.snackbar('خطأ', 'اختر ملف الفيديو', backgroundColor: AppColors.error, colorText: Colors.white);
                                return;
                              }
                              final hasExistingFile =
                                  lecture.url == null || lecture.url!.isEmpty;
                              if (!hasExistingFile) {
                                Get.snackbar('خطأ', 'اختر ملف الفيديو لاستبدال الرابط',
                                    backgroundColor: AppColors.error, colorText: Colors.white);
                                return;
                              }
                            }
                          }
                          if (isEdit) {
                            ctrl.updateLecture(
                              lecture.id,
                              courseId,
                              title: titleCtrl.text.trim(),
                              type: selectedType.value,
                              url: selectedType.value == 'TEXT'
                                  ? null
                                  : (urlCtrl.text.isNotEmpty ? urlCtrl.text.trim() : null),
                              content: selectedType.value == 'TEXT'
                                  ? (contentCtrl.text.isNotEmpty ? contentCtrl.text.trim() : null)
                                  : null,
                              sortOrder: sortOrder,
                              videoFilePath: selectedType.value == 'VIDEO'
                                  ? selectedVideoPath.value
                                  : null,
                            );
                          } else {
                            ctrl.createLecture(
                              courseId,
                              title: titleCtrl.text.trim(),
                              type: selectedType.value,
                              url: urlCtrl.text.isNotEmpty ? urlCtrl.text.trim() : null,
                              content: contentCtrl.text.isNotEmpty ? contentCtrl.text.trim() : null,
                              sortOrder: sortOrder,
                              videoFilePath: selectedType.value == 'VIDEO'
                                  ? selectedVideoPath.value
                                  : null,
                            );
                          }
                        },
                        icon: isEdit ? Icons.save_outlined : Icons.add,
                      ),
                    ],
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPicker({
    required Rxn<String> selectedPath,
    required RxDouble selectedSize,
    required LectureModel? lecture,
    required VoidCallback onPick,
  }) {
    final existingFileKept = lecture != null &&
        lecture.isVideo &&
        (lecture.url == null || lecture.url!.isEmpty);
    return Obx(() {
      final path = selectedPath.value;
      if (path == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file),
                label: const Text('اختر ملف الفيديو'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              existingFileKept
                  ? '✓ الفيديو الحالي محفوظ — يمكنك اختيار ملف جديد للاستبدال'
                  : 'الصيغ المسموحة: mp4، webm، mov، mkv — حتى 2048MB',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        );
      }
      final name = path.split(RegExp(r'[/\\]')).last;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.courseCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            const Icon(Icons.movie, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${(selectedSize.value / (1024 * 1024)).toStringAsFixed(1)} MB • جاهز للرفع',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () {
                selectedPath.value = null;
                selectedSize.value = 0;
              },
            ),
          ],
        ),
      );
    });
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
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.courseCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
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
