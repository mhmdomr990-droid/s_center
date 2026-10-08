import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/lecture_model.dart';
import '../../../data/services/upload_manager.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../courses/teacher_courses_controller.dart';

class AddEditLecturePage extends StatefulWidget {
  const AddEditLecturePage({super.key});

  @override
  State<AddEditLecturePage> createState() => _AddEditLecturePageState();
}

class _AddEditLecturePageState extends State<AddEditLecturePage> {
  late final int courseId;
  late final LectureModel? lecture;
  late final bool isEdit;

  late final TextEditingController titleCtrl;
  late final TextEditingController urlCtrl;
  late final TextEditingController contentCtrl;
  late final TextEditingController sortCtrl;
  late final RxString selectedType;

  final selectedVideoPath = Rxn<String>();
  final selectedVideoSize = 0.0.obs;
  final selectedVideoBytes = Rxn<Uint8List>();
  final selectedVideoName = Rxn<String>();

  final selectedPdfPath = Rxn<String>();
  final selectedPdfSize = 0.0.obs;
  final selectedPdfBytes = Rxn<Uint8List>();
  final selectedPdfName = Rxn<String>();

  bool compressVideo = false;

  static const allowedVideoExts = ['mp4', 'webm', 'mov', 'mkv'];
  static const maxVideoBytes = 2048 * 1024 * 1024;
  static const maxPdfBytes = 2048 * 1024 * 1024;

  Timer? _draftTimer;
  bool _restoring = false;
  bool _submitting = false;
  bool _submitted = false;

  String get _draftKey =>
      '${TeacherCoursesController.draftKeyPrefix}$courseId';

  @override
  void initState() {
    super.initState();
    // الشريط العائم مخفي هنا — تعرض الصفحة تقدمها بنفسها
    Get.find<UploadManager>().overlaySuppressed.value = true;
    final args = Get.arguments as Map<String, dynamic>;
    courseId = args['courseId'] as int;
    lecture = args['lecture'] as LectureModel?;
    isEdit = lecture != null;

    titleCtrl = TextEditingController(text: lecture?.title ?? '');
    urlCtrl = TextEditingController(text: lecture?.url ?? '');
    contentCtrl = TextEditingController(text: lecture?.content ?? '');
    sortCtrl =
        TextEditingController(text: (lecture?.sortOrder ?? 0).toString());
    selectedType = (lecture?.type ?? 'VIDEO').obs;

    if (!isEdit) {
      _restoreDraft();
    }

    urlCtrl.addListener(_onUrlChanged);
    titleCtrl.addListener(_scheduleDraftSave);
    contentCtrl.addListener(_scheduleDraftSave);
    sortCtrl.addListener(_scheduleDraftSave);
  }

  @override
  void dispose() {
    // عد الشريط العائم — إن بقي الرفع مستمراً بعد الخروج من الصفحة
    Get.find<UploadManager>().overlaySuppressed.value = false;
    _draftTimer?.cancel();
    // أي تغييرات معلقة تُحفظ لحظة الخروج — إلا أثناء/بعد إرسال ناجح
    // (عندها تُمسح المسودة من الكونترولر ولا نُعيد كتابتها هنا)
    if (!isEdit && !_restoring && !_submitting && !_submitted) {
      unawaited(_saveDraft());
    }
    titleCtrl.dispose();
    urlCtrl.dispose();
    contentCtrl.dispose();
    sortCtrl.dispose();
    super.dispose();
  }

  // ---------- مسودة الاستمارة (تُحفظ تلقائياً وتُسترجع بعد الإغلاق) ----------

  void _onUrlChanged() {
    if (_restoring) return;
    // كتابة رابط تُلغي اختيار الملف (لا يُرسل الاثنان معاً)
    if (urlCtrl.text.trim().isNotEmpty) {
      selectedPdfPath.value = null;
      selectedPdfBytes.value = null;
      selectedPdfName.value = null;
    }
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (_restoring || isEdit) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    // أثناء/بعد الإرسال لا تُكتب المسودة (النجاح يحذفها في الكونترولر)
    if (isEdit || _restoring || _submitting || _submitted) return;
    // البناء متزامن قبل أي await — ليبقى آمناً عند استدعاؤه من dispose
    final payload = jsonEncode({
      'title': titleCtrl.text,
      'url': urlCtrl.text,
      'content': contentCtrl.text,
      'sort': sortCtrl.text,
      'type': selectedType.value,
      // على الويب path هو data URL ضخم — لا يُخزَّن ولا يُسترجع
      'video_path': kIsWeb ? null : selectedVideoPath.value,
      'video_name': selectedVideoName.value,
      'video_size': selectedVideoSize.value,
      'pdf_path': kIsWeb ? null : selectedPdfPath.value,
      'pdf_name': selectedPdfName.value,
      'pdf_size': selectedPdfSize.value,
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey, payload);
    } catch (_) {}
  }

  Future<void> _restoreDraft() async {
    _restoring = true;
    var hasContent = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) return;
      final d = jsonDecode(raw) as Map<String, dynamic>;

      final t = (d['title'] as String?) ?? '';
      final u = (d['url'] as String?) ?? '';
      final c = (d['content'] as String?) ?? '';
      final s = (d['sort'] as String?) ?? '0';
      final ty = (d['type'] as String?) ?? 'VIDEO';

      titleCtrl.text = t;
      urlCtrl.text = u;
      contentCtrl.text = c;
      sortCtrl.text = s;
      selectedType.value =
          const ['VIDEO', 'PDF', 'TEXT'].contains(ty) ? ty : 'VIDEO';

      final vp = d['video_path'] as String?;
      if (vp != null && vp.isNotEmpty) {
        if (!kIsWeb && File(vp).existsSync()) {
          selectedVideoPath.value = vp;
          selectedVideoName.value = d['video_name'] as String?;
          selectedVideoSize.value =
              (d['video_size'] as num?)?.toDouble() ?? 0;
        } else if (d['video_name'] != null) {
          _notifyMissingFile();
        }
      }
      final pp = d['pdf_path'] as String?;
      if (pp != null && pp.isNotEmpty) {
        if (!kIsWeb && File(pp).existsSync()) {
          selectedPdfPath.value = pp;
          selectedPdfName.value = d['pdf_name'] as String?;
          selectedPdfSize.value = (d['pdf_size'] as num?)?.toDouble() ?? 0;
        } else if (d['pdf_name'] != null) {
          _notifyMissingFile();
        }
      }

      hasContent = t.isNotEmpty ||
          u.isNotEmpty ||
          c.isNotEmpty ||
          s != '0' ||
          ty != 'VIDEO' ||
          selectedVideoPath.value != null ||
          selectedPdfPath.value != null;
    } catch (_) {
      // مسودة تالفة — نتجاهلها ولا نكسر الصفحة
    } finally {
      _restoring = false;
    }
    if (hasContent && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.snackbar(
          'مسودة',
          'تم استرجاع ما كتبته سابقاً',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      });
    }
  }

  void _notifyMissingFile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.snackbar(
        'تنبيه',
        'الملف المختار لم يعد متاحاً — أعد اختياره',
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
    });
  }

  // ---------- اختيار الملفات ----------

  Future<void> pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: kIsWeb, // على الويب تُطلب البايتات (لا مسار ملف)
    );
    final file = result?.files.single;
    if (file == null) return;
    final ext = file.name.split('.').last.toLowerCase();
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
    selectedVideoPath.value = file.path;
    selectedVideoSize.value = file.size.toDouble();
    selectedVideoBytes.value = kIsWeb ? file.bytes : null;
    selectedVideoName.value = file.name;
    _scheduleDraftSave();
  }

  Future<void> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: kIsWeb, // على الويب تُطلب البايتات (لا مسار ملف)
    );
    final file = result?.files.single;
    if (file == null) return;
    // الفحص من اسم الملف الحقيقي — path على الويب ليس مساراً (data URL)
    if (file.name.split('.').last.toLowerCase() != 'pdf') {
      Get.snackbar('خطأ', 'الصيغة المسموحة: pdf',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    if (file.size > maxPdfBytes) {
      Get.snackbar('خطأ', 'حجم الملف يتجاوز الحد الأقصى 2048MB',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    selectedPdfPath.value = file.path;
    selectedPdfSize.value = file.size.toDouble();
    selectedPdfBytes.value = kIsWeb ? file.bytes : null;
    selectedPdfName.value = file.name;
    urlCtrl.clear();
    _scheduleDraftSave();
  }

  Future<void> _submit() async {
    if (titleCtrl.text.isEmpty) {
      Get.snackbar('خطأ', 'أدخل عنوان المحاضرة',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    final sortOrder = int.tryParse(sortCtrl.text.trim());
    if (selectedType.value == 'PDF') {
      final hasFile = selectedPdfPath.value != null;
      final hasUrl = urlCtrl.text.trim().isNotEmpty;
      final hasStoredFile = isEdit &&
          lecture!.isPdf &&
          (lecture!.url == null || lecture!.url!.isEmpty);
      if (!hasFile && !hasUrl && !hasStoredFile) {
        Get.snackbar('خطأ', 'ارفع ملف PDF أو أدخل رابط الملف',
            backgroundColor: AppColors.error, colorText: Colors.white);
        return;
      }
    }
    if (selectedType.value == 'VIDEO') {
      if (selectedVideoPath.value == null) {
        if (!isEdit) {
          Get.snackbar('خطأ', 'اختر ملف الفيديو',
              backgroundColor: AppColors.error, colorText: Colors.white);
          return;
        }
        final hasExistingFile =
            lecture!.url == null || lecture!.url!.isEmpty;
        if (!hasExistingFile) {
          Get.snackbar('خطأ', 'اختر ملف الفيديو لاستبدال الرابط',
              backgroundColor: AppColors.error, colorText: Colors.white);
          return;
        }
      }
    }

    _draftTimer?.cancel();
    _submitting = true;
    final ctrl = Get.find<TeacherCoursesController>();
    try {
      if (isEdit) {
        await ctrl.updateLecture(
          lecture!.id,
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
          compress: compressVideo,
          videoFilePath: selectedType.value == 'VIDEO'
              ? selectedVideoPath.value
              : (selectedType.value == 'PDF' &&
                      urlCtrl.text.trim().isEmpty
                  ? selectedPdfPath.value
                  : null),
          fileBytes: selectedType.value == 'VIDEO'
              ? selectedVideoBytes.value
              : (selectedType.value == 'PDF' &&
                      urlCtrl.text.trim().isEmpty
                  ? selectedPdfBytes.value
                  : null),
          fileName: selectedType.value == 'VIDEO'
              ? selectedVideoName.value
              : (selectedType.value == 'PDF' &&
                      urlCtrl.text.trim().isEmpty
                  ? selectedPdfName.value
                  : null),
        );
      } else {
        final ok = await ctrl.createLecture(
          courseId,
          title: titleCtrl.text.trim(),
          type: selectedType.value,
          url: urlCtrl.text.isNotEmpty ? urlCtrl.text.trim() : null,
          content:
              contentCtrl.text.isNotEmpty ? contentCtrl.text.trim() : null,
          sortOrder: sortOrder,
          compress: compressVideo,
          videoFilePath: selectedType.value == 'VIDEO'
              ? selectedVideoPath.value
              : (selectedType.value == 'PDF' &&
                      urlCtrl.text.trim().isEmpty
                  ? selectedPdfPath.value
                  : null),
          fileBytes: selectedType.value == 'VIDEO'
              ? selectedVideoBytes.value
              : (selectedType.value == 'PDF' &&
                      urlCtrl.text.trim().isEmpty
                  ? selectedPdfBytes.value
                  : null),
          fileName: selectedType.value == 'VIDEO'
              ? selectedVideoName.value
              : (selectedType.value == 'PDF' &&
                      urlCtrl.text.trim().isEmpty
                  ? selectedPdfName.value
                  : null),
        );
        // نجاح ⇐ الحفظ النهائي للمسودة ممنوع (حُذفت من الكونترولر)
        _submitted = ok;
      }
    } finally {
      // فشل ⇐ الصفحة باقية ⇐ استئناف حفظ المسودة تلقائياً
      _submitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          GradientAppBar(title: isEdit ? 'تعديل محاضرة' : 'إضافة محاضرة'),
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
                    _buildTypeChip(selectedType, 'VIDEO', 'فيديو',
                        Icons.videocam),
                    const SizedBox(width: 8),
                    _buildTypeChip(selectedType, 'PDF', 'PDF',
                        Icons.picture_as_pdf),
                    const SizedBox(width: 8),
                    _buildTypeChip(selectedType, 'TEXT', 'نص',
                        Icons.article),
                  ],
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (selectedType.value == 'VIDEO') {
                return _buildVideoPicker(
                  lecture: lecture,
                );
              }
              if (selectedType.value == 'PDF') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPdfPicker(
                      lecture: lecture,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      labelText: 'أو رابط PDF (بدون رفع ملف)',
                      prefixIcon: Icons.link,
                      controller: urlCtrl,
                    ),
                  ],
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
                  final um = Get.find<UploadManager>();
                  final compressing = um.compressing.value;
                  final compressProgress = um.compressProgress.value;
                  final compressEta = um.compressEta.value;
                  final uploading = um.progress.value;
                  final willSendFile = selectedType.value == 'VIDEO'
                      ? (selectedVideoPath.value != null ||
                          selectedVideoBytes.value != null)
                      : (selectedType.value == 'PDF' &&
                          urlCtrl.text.trim().isEmpty &&
                          (selectedPdfPath.value != null ||
                              selectedPdfBytes.value != null));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (compressing) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: compressProgress > 0
                                ? compressProgress
                                : null,
                            minHeight: 8,
                            backgroundColor: AppColors.courseCard,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          compressProgress > 0
                              ? 'جاري ضغط الفيديو... ${(compressProgress * 100).toStringAsFixed(0)}%${compressEta > 0 ? ' — متبقٍ ${compressEta >= 60 ? '${(compressEta / 60).round()} د' : '$compressEta ث'}' : ''}'
                              : 'جاري ضغط الفيديو...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                      ] else if (uploading > 0 ||
                          (ctrl.isSaving.value && willSendFile)) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: uploading > 0 ? uploading : null,
                            minHeight: 8,
                            backgroundColor: AppColors.courseCard,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          uploading > 0
                              ? 'جاري الرفع... ${(uploading * 100).toStringAsFixed(0)}%'
                              : 'جاري الرفع...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomButton(
                        text:
                            isEdit ? 'حفظ التغييرات' : 'إضافة المحاضرة',
                        isLoading: ctrl.isSaving.value,
                        onPressed: _submit,
                        icon:
                            isEdit ? Icons.save_outlined : Icons.add,
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

  Widget _buildVideoPicker({required LectureModel? lecture}) {
    final existingFileKept = lecture != null &&
        lecture.isVideo &&
        (lecture.url == null || lecture.url!.isEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
      final path = selectedVideoPath.value;
      if (path == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickVideo,
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
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        );
      }
      final name =
          selectedVideoName.value ?? path.split(RegExp(r'[/\\]')).last;
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    '${(selectedVideoSize.value / (1024 * 1024)).toStringAsFixed(1)} MB • جاهز للرفع',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () {
                selectedVideoPath.value = null;
                selectedVideoSize.value = 0;
                selectedVideoBytes.value = null;
                selectedVideoName.value = null;
                _scheduleDraftSave();
              },
            ),
          ],
        ),
      );
        }),
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
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          value: compressVideo,
          activeThumbColor: AppColors.primary,
          onChanged: (value) => setState(() => compressVideo = value),
        ),
      ],
    );
  }

  Widget _buildPdfPicker({required LectureModel? lecture}) {
    final existingFileKept = lecture != null &&
        lecture.isPdf &&
        (lecture.url == null || lecture.url!.isEmpty);
    return Obx(() {
      final path = selectedPdfPath.value;
      if (path == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickPdf,
                icon: const Icon(Icons.upload_file),
                label: const Text('اختر ملف PDF'),
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
                  ? '✓ الملف الحالي محفوظ — يمكنك اختيار ملف جديد للاستبدال'
                  : 'الصيغة المسموحة: pdf — حتى 2048MB',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        );
      }
      final name =
          selectedPdfName.value ?? path.split(RegExp(r'[/\\]')).last;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.courseCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: AppColors.error),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    '${(selectedPdfSize.value / (1024 * 1024)).toStringAsFixed(1)} MB • جاهز للرفع',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () {
                selectedPdfPath.value = null;
                selectedPdfSize.value = 0;
                selectedPdfBytes.value = null;
                selectedPdfName.value = null;
                _scheduleDraftSave();
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTypeChip(
      RxString selected, String value, String label, IconData icon) {
    final isSelected = selected.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          selected.value = value;
          _scheduleDraftSave();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.courseCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
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
