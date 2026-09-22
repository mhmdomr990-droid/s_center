import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/lecture_model.dart';

class LectureController extends GetxController {
  final currentIndex = 0.obs;
  late List<LectureModel> lectures;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    lectures = args['lectures'] as List<LectureModel>;
    currentIndex.value = args['currentIndex'] as int;
  }

  LectureModel get currentLecture => lectures[currentIndex.value];
  bool get hasPrevious => currentIndex.value > 0;
  bool get hasNext => currentIndex.value < lectures.length - 1;

  void previousLecture() {
    if (hasPrevious) currentIndex.value--;
  }

  void nextLecture() {
    if (hasNext) currentIndex.value++;
  }

  Future<void> openPdf(String? url) async {
    if (url == null || url.isEmpty) {
      Get.snackbar('خطأ', 'رابط الملف غير متاح', backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class LectureViewPage extends StatelessWidget {
  const LectureViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LectureController>(
      init: LectureController(),
      builder: (ctrl) {
        final lecture = ctrl.currentLecture;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(lecture.title),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(lecture.type, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        const Spacer(),
                        Text('${ctrl.currentIndex.value + 1} / ${ctrl.lectures.length}', style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(lecture.title, style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (lecture.isVideo && lecture.url != null && lecture.url!.isNotEmpty)
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_outline, color: Colors.white, size: 64),
                        const SizedBox(height: 12),
                        Text('اضغط لتشغيل الفيديو', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(lecture.url!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text('فتح في المتصفح', style: GoogleFonts.cairo()),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              else if (lecture.isPdf)
                GestureDetector(
                  onTap: () => ctrl.openPdf(lecture.url),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('اضغط لفتح ملف PDF', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                )
              else if (lecture.isText && lecture.content != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(lecture.content!, style: AppTextStyles.bodyLarge.copyWith(height: 1.8)),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(lecture.typeIcon == '🎬' ? Icons.videocam : Icons.article, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text('محتوى المحاضرة غير متاح', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.hasPrevious ? ctrl.previousLecture : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text('السابق', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.divider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.hasNext ? ctrl.nextLecture : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text('التالي', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.divider,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
