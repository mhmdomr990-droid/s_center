import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/lecture_model.dart';
import '../../../data/services/upload_manager.dart';
import '../courses/teacher_courses_controller.dart';

/// نافذة «إضافة/تعديل محاضرة» للمعلم — مطابقة لنافذة الأدمن
/// (content_page.dart:_showLectureDialog) في الشكل والحقول والسلوك.
/// تُغلق نفسها تلقائياً بعد الرفع/الحفظ الناجح.
void showTeacherLectureDialog(
  BuildContext context,
  TeacherCoursesController ctrl, {
  required int courseId,
  LectureModel? lecture,
}) {
  const allowedVideoExts = ['mp4', 'webm', 'mov', 'mkv'];
  const maxUploadBytes = 2048 * 1024 * 1024;

  final isEdit = lecture != null;
  final existingType = lecture?.type ?? 'VIDEO';
  var selectedType = isEdit ? existingType : 'VIDEO';
  final titleCtrl = TextEditingController(text: lecture?.title ?? '');
  final urlCtrl = TextEditingController(text: lecture?.url ?? '');
  final contentCtrl = TextEditingController(text: lecture?.content ?? '');
  final sortCtrl =
      TextEditingController(text: '${lecture?.sortOrder ?? 0}');

  String? videoPath;
  Uint8List? videoBytes;
  String? videoName;
  double videoSize = 0;
  String? pdfPath;
  Uint8List? pdfBytes;
  String? pdfName;
  double pdfSize = 0;
  var compressVideo = false;

  final existingUrlEmpty = (lecture?.url ?? '').isEmpty;
  // ملف مخزّن داخل الخادم (لا رابط) — يبقى صالحاً عند الحفظ دون رفع جديد
  bool hasStoredVideo() => isEdit && existingType == 'VIDEO' && existingUrlEmpty;
  bool hasStoredPdf() => isEdit && existingType == 'PDF' && existingUrlEmpty;

  void err(String msg) => Get.snackbar('خطأ', msg,
      backgroundColor: Colors.red, colorText: Colors.white);

  final um = Get.find<UploadManager>();
  final prevSuppressed = um.overlaySuppressed.value;
  Future.microtask(() => um.overlaySuppressed.value = true);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> pickVideo() async {
          final result = await FilePicker.pickFiles(
              type: FileType.video, allowMultiple: false, withData: kIsWeb);
          final file = result?.files.single;
          if (file == null) return;
          final ext = file.name.split('.').last.toLowerCase();
          if (!allowedVideoExts.contains(ext)) {
            err('الصيغ المسموحة: mp4، webm، mov، mkv');
            return;
          }
          if (file.size > maxUploadBytes) {
            err('حجم الملف يتجاوز الحد الأقصى 2048MB');
            return;
          }
          setState(() {
            videoPath = file.path;
            videoBytes = kIsWeb ? file.bytes : null;
            videoName = file.name;
            videoSize = file.size.toDouble();
          });
        }

        Future<void> pickPdf() async {
          final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              allowMultiple: false,
              withData: kIsWeb);
          final file = result?.files.single;
          if (file == null) return;
          if (file.name.split('.').last.toLowerCase() != 'pdf') {
            err('الصيغة المسموحة: pdf');
            return;
          }
          if (file.size > maxUploadBytes) {
            err('حجم الملف يتجاوز الحد الأقصى 2048MB');
            return;
          }
          setState(() {
            pdfPath = file.path;
            pdfBytes = kIsWeb ? file.bytes : null;
            pdfName = file.name;
            pdfSize = file.size.toDouble();
            urlCtrl.clear();
          });
        }

        Future<void> submit() async {
          final title = titleCtrl.text.trim();
          final url = urlCtrl.text.trim();
          final content = contentCtrl.text.trim();
          final sortOrder = int.tryParse(sortCtrl.text.trim());
          if (title.isEmpty) {
            err('أدخل عنوان المحاضرة');
            return;
          }
          if (selectedType == 'PDF') {
            final hasFile = pdfPath != null;
            final hasUrl = url.isNotEmpty;
            if (!hasFile && !hasUrl && !hasStoredPdf()) {
              err('ارفع ملف PDF أو أدخل رابط الملف');
              return;
            }
          }
          if (selectedType == 'VIDEO' && videoPath == null && !hasStoredVideo()) {
            err(isEdit
                ? 'اختر ملف الفيديو لاستبدال الملف الحالي'
                : 'اختر ملف الفيديو');
            return;
          }

          // الملف يُرسل في حقل `video` — الفيديو دائماً، وPDF عند غياب الرابط
          final sendFile = selectedType == 'VIDEO'
              ? videoPath != null
              : (selectedType == 'PDF' && url.isEmpty && pdfPath != null);

          final bool ok;
          if (isEdit) {
            ok = await ctrl.updateLecture(
              lecture.id,
              courseId,
              title: title,
              type: selectedType,
              url: selectedType == 'TEXT'
                  ? null
                  : (url.isNotEmpty ? url : null),
              content: selectedType == 'TEXT'
                  ? (content.isNotEmpty ? content : null)
                  : null,
              sortOrder: sortOrder,
              compress: compressVideo,
              videoFilePath: sendFile
                  ? (selectedType == 'VIDEO' ? videoPath : pdfPath)
                  : null,
              fileBytes: sendFile
                  ? (selectedType == 'VIDEO' ? videoBytes : pdfBytes)
                  : null,
              fileName: sendFile
                  ? (selectedType == 'VIDEO' ? videoName : pdfName)
                  : null,
            );
          } else {
            ok = await ctrl.createLecture(
              courseId,
              title: title,
              type: selectedType,
              url: url.isNotEmpty ? url : null,
              content: content.isNotEmpty ? content : null,
              sortOrder: sortOrder,
              compress: compressVideo,
              videoFilePath: sendFile
                  ? (selectedType == 'VIDEO' ? videoPath : pdfPath)
                  : null,
              fileBytes: sendFile
                  ? (selectedType == 'VIDEO' ? videoBytes : pdfBytes)
                  : null,
              fileName: sendFile
                  ? (selectedType == 'VIDEO' ? videoName : pdfName)
                  : null,
            );
          }
          if (ok && dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        }

        Widget typeChip(String value, String label, IconData icon) {
          final sel = selectedType == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedType = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.courseCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.cardBorder,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color:
                            sel ? AppColors.primary : AppColors.textSecondary,
                        size: 22),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                          color:
                              sel ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        )),
                  ],
                ),
              ),
            ),
          );
        }

        Widget pickButton(String label, VoidCallback onPressed) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.upload_file),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          );
        }

        Widget selectedFile(String name, double sizeBytes, IconData icon,
            Color color, VoidCallback onClear) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.courseCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB • جاهز للرفع',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: onClear,
                ),
              ],
            ),
          );
        }

        final hintStyle =
            TextStyle(fontSize: 12, color: AppColors.textSecondary);

        return AlertDialog(
          title: Text(isEdit ? 'تعديل المحاضرة' : 'محاضرة جديدة'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'العنوان', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      typeChip('VIDEO', 'فيديو', Icons.videocam),
                      const SizedBox(width: 8),
                      typeChip('PDF', 'PDF', Icons.picture_as_pdf),
                      const SizedBox(width: 8),
                      typeChip('TEXT', 'نص', Icons.article),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (selectedType == 'VIDEO') ...[
                    if (videoPath == null) ...[
                      pickButton('اختر ملف الفيديو', pickVideo),
                      const SizedBox(height: 6),
                      Text(
                        hasStoredVideo()
                            ? '✓ الفيديو الحالي محفوظ — يمكنك اختيار ملف جديد للاستبدال'
                            : 'الصيغ المسموحة: mp4، webm، mov، mkv — حتى 2048MB',
                        style: hintStyle,
                      ),
                    ] else
                      selectedFile(
                        videoName ??
                            videoPath!.split(RegExp(r'[/\\]')).last,
                        videoSize,
                        Icons.movie,
                        AppColors.primary,
                        () => setState(() {
                          videoPath = null;
                          videoBytes = null;
                          videoName = null;
                          videoSize = 0;
                        }),
                      ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        'ضغط الفيديو قبل الرفع',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'يقلل حجم الفيديو قبل الرفع (بلا حد أدنى للحجم)',
                        style: hintStyle,
                      ),
                      value: compressVideo,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) =>
                          setState(() => compressVideo = value),
                    ),
                  ] else if (selectedType == 'PDF') ...[
                    if (pdfPath == null) ...[
                      pickButton('اختر ملف PDF', pickPdf),
                      const SizedBox(height: 6),
                      Text(
                        hasStoredPdf()
                            ? '✓ الملف الحالي محفوظ — يمكنك اختيار ملف جديد للاستبدال'
                            : 'الصيغة المسموحة: pdf — حتى 2048MB',
                        style: hintStyle,
                      ),
                    ] else
                      selectedFile(
                        pdfName ?? pdfPath!.split(RegExp(r'[/\\]')).last,
                        pdfSize,
                        Icons.picture_as_pdf,
                        AppColors.error,
                        () => setState(() {
                          pdfPath = null;
                          pdfBytes = null;
                          pdfName = null;
                          pdfSize = 0;
                        }),
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: urlCtrl,
                      keyboardType: TextInputType.url,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty && pdfPath != null) {
                          setState(() {
                            pdfPath = null;
                            pdfBytes = null;
                            pdfName = null;
                            pdfSize = 0;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'أو رابط PDF (بدون رفع ملف)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: contentCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          labelText: 'المحتوى النصي',
                          border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: sortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'الترتيب (رقمي)',
                        border: OutlineInputBorder()),
                  ),
                  Obx(() {
                    final compressing = um.compressing.value;
                    final cp = um.compressProgress.value;
                    final eta = um.compressEta.value;
                    final up = um.progress.value;
                    final busy = ctrl.isSaving.value;
                    final willSendFile = selectedType == 'VIDEO'
                        ? (videoPath != null || videoBytes != null)
                        : (selectedType == 'PDF' &&
                            urlCtrl.text.trim().isEmpty &&
                            (pdfPath != null || pdfBytes != null));
                    if (!compressing && up <= 0 && !(busy && willSendFile)) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: compressing
                                  ? (cp > 0 ? cp : null)
                                  : (up > 0 ? up : null),
                              minHeight: 8,
                              backgroundColor: AppColors.courseCard,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            compressing
                                ? (cp > 0
                                    ? 'جاري ضغط الفيديو... ${(cp * 100).toStringAsFixed(0)}%${eta > 0 ? ' — متبقٍ ${eta >= 60 ? '${(eta / 60).round()} د' : '$eta ث'}' : ''}'
                                    : 'جاري ضغط الفيديو...')
                                : (up > 0
                                    ? 'جاري الرفع... ${(up * 100).toStringAsFixed(0)}%'
                                    : 'جاري الرفع...'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            Obx(() => TextButton(
                  onPressed: ctrl.isSaving.value
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                )),
            Obx(() => TextButton(
                  onPressed: ctrl.isSaving.value ? null : submit,
                  child:
                      Text(ctrl.isSaving.value ? 'جارٍ الحفظ...' : 'حفظ'),
                )),
          ],
        );
      },
    ),
  ).whenComplete(() =>
      Future.microtask(() => um.overlaySuppressed.value = prevSuppressed));
}
