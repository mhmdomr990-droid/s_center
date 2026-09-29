import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/status_pill.dart';
import '../../../utils/format.dart';
import 'courses_controller.dart';
import 'lectures_controller.dart';
import 'specializations_controller.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'المحتوى'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _segmentButton(0, 'التخصصات'),
                const SizedBox(width: 8),
                _segmentButton(1, 'الدورات'),
                const SizedBox(width: 8),
                _segmentButton(2, 'المحاضرات'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: IndexedStack(
              index: _segment,
              children: const [
                _SpecializationsView(),
                _CoursesView(),
                _LecturesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(int index, String label) {
    final isSelected = _segment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.courseCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// التخصصات
// ---------------------------------------------------------------------------

class _SpecializationsView extends StatelessWidget {
  const _SpecializationsView();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SpecializationsController>(
      init: SpecializationsController(),
      builder: (ctrl) {
        return Obx(() {
          if (ctrl.isLoading.value && ctrl.items.isEmpty) {
            return const LoadingListShimmer();
          }
          return RefreshIndicator(
            onRefresh: ctrl.load,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: ctrl.create,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('إضافة تخصص'),
                    ),
                  ],
                ),
                if (ctrl.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyState(
                      icon: Icons.category_outlined,
                      title: 'لا توجد تخصصات',
                      subtitle: 'أضف أول تخصص الآن',
                    ),
                  )
                else
                  ...ctrl.items.map((item) {
                    final published = item['is_published'] ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.courseCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? '',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                StatusPill(
                                  label: published ? 'منشور' : 'مخفي',
                                  color: published ? AppColors.success : AppColors.warning,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'تعديل',
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary, size: 21),
                            onPressed: () => ctrl.edit(item),
                          ),
                          IconButton(
                            tooltip: published ? 'إخفاء' : 'نشر',
                            icon: Icon(
                              published ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.warning,
                              size: 21,
                            ),
                            onPressed: () => ctrl.togglePublished(item),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 21),
                            onPressed: () => ctrl.delete(item),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// الكورسات
// ---------------------------------------------------------------------------

class _CoursesView extends StatelessWidget {
  const _CoursesView();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CoursesController>(
      init: CoursesController(),
      builder: (ctrl) {
        return Obx(() {
          if (ctrl.isLoading.value && ctrl.items.isEmpty) {
            return const LoadingListShimmer();
          }
          return RefreshIndicator(
            onRefresh: ctrl.load,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                CustomTextField(
                  labelText: 'بحث في الدورات',
                  prefixIcon: Icons.search_rounded,
                  controller: ctrl.searchCtrl,
                  onChanged: ctrl.onSearchChanged,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: ctrl.selectedSpecId.value,
                          hint: const Text('التخصص', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                            ...ctrl.specializations.map((s) => DropdownMenuItem<int?>(
                                  value: s['id'] as int,
                                  child: Text('${s['name']}',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (value) {
                            ctrl.selectedSpecId.value = value;
                            ctrl.load();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: ctrl.selectedYear.value,
                          hint: const Text('السنة', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                            ...List.generate(
                                5,
                                (i) => DropdownMenuItem<int?>(
                                      value: i + 1,
                                      child: Text('السنة ${i + 1}',
                                          style: const TextStyle(fontSize: 13)),
                                    )),
                          ],
                          onChanged: (value) {
                            ctrl.selectedYear.value = value;
                            ctrl.load();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _showCourseDialog(context, ctrl),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'دورة جديدة',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ctrl.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'لا توجد دورات',
                      subtitle: 'أضف دورة من زر +',
                    ),
                  )
                else
                  ...ctrl.items.map((course) {
                    final published = course['is_published'] ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.courseCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(course['name'] ?? '',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w700)),
                              ),
                              StatusPill(
                                label: published ? 'منشور' : 'مخفي',
                                color: published ? AppColors.success : AppColors.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${course['specialization_name'] ?? ''} • السنة ${course['year'] ?? ''}'
                            '${course['teacher_full_name'] != null ? ' • ${course['teacher_full_name']}' : ''}',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text('${formatAmount(course['price'])} SYP',
                              style: AppTextStyles.caption
                                  .copyWith(fontWeight: FontWeight.w700)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primary, size: 20),
                                onPressed: () => _showCourseDialog(context, ctrl,
                                    course: course),
                              ),
                              IconButton(
                                icon: Icon(
                                  published
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                onPressed: () => ctrl.togglePublished(course),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () => ctrl.delete(course),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  static void _showCourseDialog(BuildContext context, CoursesController ctrl,
      {Map<String, dynamic>? course}) {
    final isEdit = course != null;
    final nameCtrl = TextEditingController(text: course?['name'] ?? '');
    final priceCtrl =
        TextEditingController(text: course != null ? formatAmount(course['price']) : '');
    final descCtrl = TextEditingController(text: course?['description'] ?? '');
    final percentCtrl =
        TextEditingController(text: course != null ? '${course['teacher_percent'] ?? ''}' : '');
    int? specId = course?['specialization_id'] as int? ??
        (ctrl.specializations.isNotEmpty ? ctrl.specializations.first['id'] as int : null);
    int? year = (course?['year'] as int?) ?? 1;
    int? teacherId = course?['teacher_id'] as int?;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(isEdit ? 'تعديل الدورة' : 'دورة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'اسم الدورة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: specId,
                  decoration:
                      const InputDecoration(labelText: 'التخصص', border: OutlineInputBorder()),
                  items: ctrl.specializations
                      .map((s) => DropdownMenuItem<int?>(
                            value: s['id'] as int,
                            child: Text('${s['name']}', overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => specId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: year,
                  decoration:
                      const InputDecoration(labelText: 'السنة الدراسية', border: OutlineInputBorder()),
                  items: List.generate(
                      5,
                      (i) => DropdownMenuItem<int?>(
                          value: i + 1, child: Text('السنة ${i + 1}'))),
                  onChanged: (value) => setState(() => year = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'السعر (SYP)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'الوصف (اختياري)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: teacherId,
                  decoration:
                      const InputDecoration(labelText: 'المعلم (اختياري)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('بدون')),
                    ...ctrl.teachers.map((t) => DropdownMenuItem<int?>(
                          value: t['teacher_id'] as int,
                          child: Text('${t['full_name']}',
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (value) => setState(() => teacherId = value),
                ),
                if (teacherId != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: percentCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'نسبة المعلم % (اختياري)', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = priceCtrl.text.trim().replaceAll(',', '');
                if (name.isEmpty || specId == null || year == null || double.tryParse(price) == null) {
                  Get.snackbar('خطأ', 'أكمل الحقول المطلوبة',
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }
                final body = <String, dynamic>{
                  'specialization_id': specId,
                  'year': year,
                  'name': name,
                  'price': price,
                  if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                  'teacher_id': teacherId,
                  if (teacherId != null &&
                      percentCtrl.text.trim().isNotEmpty &&
                      double.tryParse(percentCtrl.text.trim()) != null)
                    'teacher_percent': percentCtrl.text.trim(),
                };
                Navigator.of(dialogContext).pop();
                if (isEdit) {
                  ctrl.updateCourse(course['id'] as int, body);
                } else {
                  ctrl.createCourse(body);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// المحاضرات
// ---------------------------------------------------------------------------

class _LecturesView extends StatelessWidget {
  const _LecturesView();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LecturesController>(
      init: LecturesController(),
      builder: (ctrl) {
        return Obx(() {
          if (ctrl.isLoading.value && ctrl.items.isEmpty && ctrl.courses.isEmpty) {
            return const LoadingListShimmer();
          }
          return RefreshIndicator(
            onRefresh: ctrl.loadLectures,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          isExpanded: true,
                          value: ctrl.selectedCourseId.value,
                          hint: const Text('اختر دورة', style: TextStyle(fontSize: 13)),
                          items: ctrl.courses
                              .map((c) => DropdownMenuItem<int?>(
                                    value: c['id'] as int,
                                    child: Text('${c['name']}',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (value) => ctrl.selectCourse(value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: ctrl.selectedCourseId.value == null
                          ? null
                          : () => _showLectureDialog(context, ctrl),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'محاضرة جديدة',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ctrl.selectedCourseId.value == null)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyState(
                      icon: Icons.video_library_outlined,
                      title: 'اختر دورة أولاً',
                      subtitle: 'ستظهر محاضرات الدورة المختارة هنا',
                    ),
                  )
                else if (ctrl.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: EmptyState(
                      icon: Icons.note_alt_outlined,
                      title: 'لا توجد محاضرات',
                      subtitle: 'أضف محاضرة من زر +',
                    ),
                  )
                else
                  ...ctrl.items.map((lecture) {
                    final published = lecture['is_published'] ?? true;
                    final type = (lecture['type'] ?? '') as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.courseCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                type == 'VIDEO'
                                    ? Icons.play_circle_outline
                                    : type == 'PDF'
                                        ? Icons.picture_as_pdf_outlined
                                        : Icons.article_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(lecture['title'] ?? '',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w700)),
                              ),
                              StatusPill(
                                label: published ? 'منشور' : 'مخفي',
                                color: published ? AppColors.success : AppColors.warning,
                              ),
                            ],
                          ),
                          if (lecture['url'] != null &&
                              '${lecture['url']}'.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('${lecture['url']}',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ] else if (type == 'VIDEO' || type == 'PDF') ...[
                            const SizedBox(height: 4),
                            Text('ملف مرفوع داخل الخادم',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textHint)),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.primary, size: 20),
                                onPressed: () => _showLectureDialog(context, ctrl,
                                    lecture: lecture),
                              ),
                              IconButton(
                                icon: Icon(
                                  published
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.warning,
                                  size: 20,
                                ),
                                onPressed: () => ctrl.togglePublished(lecture),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () => ctrl.delete(lecture),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
      },
    );
  }

  static const _allowedVideoExts = ['mp4', 'webm', 'mov', 'mkv'];
  static const _maxUploadBytes = 2048 * 1024 * 1024;

  static void _showLectureDialog(BuildContext context, LecturesController ctrl,
      {Map<String, dynamic>? lecture}) {
    final isEdit = lecture != null;
    final existingType = (lecture?['type'] ?? 'TEXT') as String;
    var selectedType = isEdit ? existingType : 'VIDEO';
    final titleCtrl = TextEditingController(text: lecture?['title'] ?? '');
    final urlCtrl = TextEditingController(text: lecture?['url'] ?? '');
    final contentCtrl = TextEditingController(text: lecture?['content'] ?? '');
    final sortCtrl =
        TextEditingController(text: '${lecture?['sort_order'] ?? 0}');

    String? videoPath;
    Uint8List? videoBytes;
    String? videoName;
    double videoSize = 0;
    String? pdfPath;
    Uint8List? pdfBytes;
    String? pdfName;
    double pdfSize = 0;
    var compressVideo = false;

    final existingUrlEmpty = ((lecture?['url'] ?? '').toString().isEmpty);
    // ملف مخزّن داخل الخادم (لا رابط) — يبقى صالحاً عند الحفظ دون رفع جديد
    bool hasStoredVideo() => isEdit && existingType == 'VIDEO' && existingUrlEmpty;
    bool hasStoredPdf() => isEdit && existingType == 'PDF' && existingUrlEmpty;

    void err(String msg) => Get.snackbar('خطأ', msg,
        backgroundColor: Colors.red, colorText: Colors.white);

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
            if (!_allowedVideoExts.contains(ext)) {
              err('الصيغ المسموحة: mp4، webm، mov، mkv');
              return;
            }
            if (file.size > _maxUploadBytes) {
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
            if (file.size > _maxUploadBytes) {
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
                lecture['id'] as int,
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
                courseId: ctrl.selectedCourseId.value!,
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
                      final compressing = ctrl.compressing.value;
                      final cp = ctrl.compressProgress.value;
                      final eta = ctrl.compressEta.value;
                      final up = ctrl.uploadProgress.value;
                      final busy = ctrl.busy.value;
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
                    onPressed: ctrl.busy.value
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  )),
              Obx(() => TextButton(
                    onPressed: ctrl.busy.value ? null : submit,
                    child: Text(ctrl.busy.value ? 'جارٍ الحفظ...' : 'حفظ'),
                  )),
            ],
          );
        },
      ),
    );
  }
}
