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
                _segmentButton(1, 'الكورسات'),
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
                      tooltip: 'محاضرة جديدة (PDF/نص)',
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

  static void _showLectureDialog(BuildContext context, LecturesController ctrl,
      {Map<String, dynamic>? lecture}) {
    final isEdit = lecture != null;
    final type = (lecture?['type'] ?? 'TEXT') as String;
    // إنشاء الفيديو غير متاح من التطبيق (يتطلب رفع ملف) — الأنواع المتاحة PDF/نص
    String selectedType = isEdit ? type : 'PDF';
    final titleCtrl = TextEditingController(text: lecture?['title'] ?? '');
    final urlCtrl = TextEditingController(text: lecture?['url'] ?? '');
    final contentCtrl = TextEditingController(text: lecture?['content'] ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(isEdit ? 'تعديل المحاضرة' : 'محاضرة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration:
                        const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'PDF', child: Text('PDF')),
                      DropdownMenuItem(value: 'TEXT', child: Text('نص')),
                    ],
                    onChanged: (value) => setState(() => selectedType = value ?? 'PDF'),
                  ),
                ],
                if (!(isEdit && type == 'VIDEO')) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: isEdit && type == 'PDF'
                          ? 'رابط PDF'
                          : selectedType == 'PDF'
                              ? 'رابط PDF (إلزامي)'
                              : 'رابط خارجي (اختياري)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                if (!(isEdit && type == 'VIDEO')) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'محتوى نصي (اختياري)', border: OutlineInputBorder()),
                  ),
                ],
                if (isEdit && type == 'VIDEO') ...[
                  const SizedBox(height: 10),
                  Text(
                    'تعديلات الفيديو محدودة للعنوان والمحتوى — الرفع من الويب',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    textAlign: TextAlign.center,
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
                final title = titleCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (title.isEmpty) {
                  Get.snackbar('خطأ', 'أدخل عنوان المحاضرة',
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }
                if (!isEdit && selectedType == 'PDF' && url.isEmpty) {
                  Get.snackbar('خطأ', 'محاضرة PDF تحتاج رابطاً',
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }
                final body = <String, dynamic>{
                  'title': title,
                  if (url.isNotEmpty) 'url': url,
                  if (contentCtrl.text.trim().isNotEmpty) 'content': contentCtrl.text.trim(),
                };
                if (!isEdit) {
                  body['course_id'] = ctrl.selectedCourseId.value;
                  body['type'] = selectedType;
                }
                Navigator.of(dialogContext).pop();
                if (isEdit) {
                  ctrl.updateLecture(lecture['id'] as int, body);
                } else {
                  ctrl.createLecture(body);
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
