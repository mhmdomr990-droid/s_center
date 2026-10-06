# تشغيل محاضرات الأدمن/المعلم — 1.0.21 (تثبيت Waydroid)

## التشخيص (مُتحقَّق)
- الخادم **يسمح**: `assertCanIssueStreamToken` (`src/modules/media/controller.ts:34-60`) — أدمن: أي محاضرة؛ معلم: دورته فقط؛ تقديم الملف يتحقق من التوكن/الدور فقط لا الشراء.
- التطبيق **بلا زر تشغيل**: `AppRoutes.lectureView` يُنادى فقط من `course_detail_page.dart:323` و `downloads_page.dart:35`.
  - صف الأدمن: `content_page.dart:620-645` — تعديل/إخفاء/حذف فقط.
  - صف المعلم: `teacher_course_detail_page.dart:91-101` — قائمة منبثقة تعديل/تبديل/حذف فقط.
- `LectureController` (`lecture_view_page.dart:116-117`) يأخذ `lectures`/`currentIndex` من `Get.arguments` — لا مناطق نهاية طالب ⇐ صالح لأي دور.
- `mapLecture` (admin/service.ts:53-68) يطابق `LectureModel.fromJson` حرفياً (snake_case) ✓.
- `DownloadLectureButton` (لecture_view_page.dart:573) يستدعي `download-url` المخصص للطالب فقط ⇒ 403 لغير الطالب.

## التعديلات (3 ملفات — mobile فقط، بلا باك إند)

### 1) `mobile/lib/modules/admin/content/content_page.dart` (الحلقة سطر 572)
أول زر في `Row` أزرار الصف (قبل edit_outlined)، للنوعَين VIDEO/PDF فقط:
```dart
if (type == 'VIDEO' || type == 'PDF')
  IconButton(
    icon: const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 20),
    onPressed: () => Get.toNamed(AppRoutes.lectureView, arguments: {
      'lecture': LectureModel.fromJson(lecture),
      'lectures': ctrl.items.map(LectureModel.fromJson).toList(),
      'currentIndex': ctrl.items.indexOf(lecture),
    }),
  ),
```
+ استيراد: `../../../app/routes/app_routes.dart` و `../../../data/models/lecture_model.dart`.
(القائمة مفلترة بدورة مختارة سطر ~546 ⇐ السابق/التالي داخل الدورة.)

### 2) `mobile/lib/modules/teacher/courses/teacher_course_detail_page.dart` (قائمة PopupMenu سطر 91)
```dart
PopupMenuItem(value: 'play', child: const Text('تشغيل')),
```
ومعالج في `onSelected`:
```dart
else if (value == 'play') {
  Get.toNamed(AppRoutes.lectureView, arguments: {
    'lecture': lecture,
    'lectures': ctrl.lectures,
    'currentIndex': ctrl.lectures.indexOf(lecture),
  });
}
```
(app_routes مستورد أصلاً ✓ — `lecture` من نوع `LectureModel` من `teacher_courses_controller` ✓.)

### 3) `mobile/lib/modules/student/lecture/lecture_view_page.dart` (≈ سطر 573)
إظهار `DownloadLectureButton` + نص «تحميل بدون إنترنت» **للطالب فقط**:
`if (lecture.isPdfHosted && !kIsWeb && <user isStudent>)` — يُقرأ الدور من `Get.find<AuthController>().user.value` (أو استيراد AuthController) — مع إبقاء المنطق كما هو لبقية الحالات.

## الحالات الحدّية
- `TEXT` ⇐ بلا زر تشغيل (الخادم يرفض إصدار رابط بث).
- ملف غير `READY` ⇐ «Media file not available» (رسالة قصيرة ≤120).

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 22`, `versionName = "1.0.21"`.
3. `flutter build apk --release` ⇒ توقيع (`apksigner` + `mobile/android/key.properties` + `/home/mhmd/keys/scenter-release.jks`) ⇒ `verify` = SIGNED_OK.
4. تثبيت **Waydroid**: إن الحاوية FROZEN ⇐ `waydroid app launch com.scenter.mobile` لاستيقاظها ثم `waydroid app install <apk>` ⇐ تحقق `sudo waydroid shell dumpsys` (22/1.0.21) ⇐ إعادة إطلاق.
5. نسخة سطح المكتب إن طُلبت.

## التحقق
- أدمن: المحتوى ← المحاضرات ← زر ▶ على صف فيديو/PDF ⇐ تشغيل.
- معلم: دورتي ← الدورة ← قائمة المحاضرات ← «تشغيل» ⇐ تشغيل (دورته).
- زر التحميل لا يظهر لأدمن/المعلم.
