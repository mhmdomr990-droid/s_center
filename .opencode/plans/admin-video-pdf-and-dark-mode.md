# خطة: رفع فيديو/PDF للأدمن + زر الدارك مود

**الحالة**: معتمدة من المستخدم (توسيع الحوار، تغيير النوع عند التعديل، المفتاح في «حسابي»).
**النطاق**: `mobile/` فقط — **صفر تعديلات باك إند/ويب** (الباك إند جاهز: `POST/PATCH /admin/lectures` يقبل multipart حقل `video` — `src/modules/admin/routes.ts:105-107`، حد 2048MB وصيغ mp4/webm/mov/mkv/pdf).

## أ) منطق الفيديو/PDF — نسخ من واجهة المعلم

### 1. `lib/data/providers/admin_provider.dart`
- إضافة imports: `dart:typed_data`.
- نسخ المساعدات من `teacher_provider.dart:31-65`: `_uploadOptions` (receiveTimeout 30min)، `_fileName`، `_lectureContentType` (webm/mov/mkv/pdf/mp4)، `_lectureFile` (MultipartFile من path أو bytes).
- توسيع `createLecture`/`updateLecture` بمعاملات اختيارية `videoFilePath / fileBytes / fileName / onSendProgress`:
  - بلا ملف ⇒ JSON كما هي (لا تغيير للسلوك الحالي).
  - مع ملف ⇒ `FormData` بحقل `video` + قيم body تُحوَّل `toString()` (تخطّي null) + `_uploadOptions`.

### 2. `lib/modules/admin/content/lectures_controller.dart`
- إضافة: `isSaving`, `compressing`, `compressProgress`, `uploadProgress` (obs) + imports: `foundation` (kIsWeb)، `video_compressor.dart`، `api_exception.dart` (apiErrorMessage).
- `createLecture(body, {videoFilePath, fileBytes, fileName})` — نفس تسلسل المعلم (`teacher_courses_controller.dart:158`):
  1. VIDEO + مسار ⇒ `VideoCompressor.compressForUpload` (تتبع compressProgress) وإلا المسار الأصلي.
  2. استدعاء provider مع `onSendProgress` (uploadProgress).
  3. نجاح ⇒ `Get.back()` (إغلاق الحوار — لم يعد يُغلق مسبقاً) + snackbar نجاح + `loadLectures()` ⇒ return true.
  4. فشل ⇒ snackbar بـ`apiErrorMessage` (الحوار يبقى مفتوحاً) ⇒ return false.
  5. finally: تصفير الحالات + `VideoCompressor.deleteCache()` لو كان هناك ملف.
- `updateLecture` بالمنطق نفسه (بدون Get.back مزدوج — الحوار يُغلق من المتحكم بعد النجاح فقط).

### 3. `lib/modules/admin/content/content_page.dart` — إعادة كتابة `_showLectureDialog` (سطر 654)
- **النوع**: قائمة منسدلة **دائمة الظهور** (إنشاء وتعديل) بعناصر: فيديو/PDF/نص — الافتراضي عند الإنشاء `VIDEO` (مثل المعلم). تغيير النوع عند التعديل مسموح (الحالة يتحكم بها الـdropdown نفسه).
- **حالة محلية**: `videoPath/Name/Size`, `pdfPath/Name/Size` (+ bytes للويب).
- **قسم VIDEO**: زر «اختر ملف الفيديو» (`FilePicker`, FileType.video، فحص صيغة في `mp4/webm/mov/mkv` وحجم ≤2048MB) + بطاقة الملف المختار (اسم/حجم/زر إزالة). عند تعديل فيديو محفوظ بدون ملف جديد: «✓ الفيديو الحالي محفوظ».
- **قسم PDF**: زر «اختر ملف PDF» (فحص pdf/الحجم) + بطاقة الملف + حقل «أو رابط PDF (بدون رفع ملف)» — **استبعاد متبادل**: كتابة الرابط تمسح الملف، واختيار الملف يمسح الرابط.
- **قسم TEXT**: حقل المحتوى النصي (multiLine).
- **حقل الترتيب الرقمي** (مثل المعلم).
- **فحوص الإرسال** مطابقة لـ`add_edit_lecture_page.dart:279-313`:
  - العنوان إلزامي؛ VIDEO ⇒ ملف جديد أو فيديو محفوظ (تعديل)؛ PDF ⇒ ملف أو رابط أو ملف محفوظ (تعديل).
- **بنية body**: `title` + `type` دائمًا؛ `url` فقط لو غير فارغ وغير TEXT؛ `content` فقط لو غير فارغ وTEXT؛ `sort_order` لو مُحلّل؛ `course_id` عند الإنشاء.
- **مُعامل الملف**: VIDEO ⇒ مسار الفيديو؛ PDF بدون رابط ⇒ مسار الـPDF؛ غير ذلك null.
- **أشرطة التقدّم**: `Obx` داخل الحوار — bar ضغط (compressing) ثم bar رفع % (uploadProgress)؛ زر «حفظ» معطّل ويعرض «جاري الرفع...» أثناء `isSaving`؛ «إلغاء» معطّل أثناء الرفع أيضاً.
- حذف ملاحظة «الرفع من الويب» وحذف قيد عدم تغيير النوع.
- (بدون ميزة المسودة التلقائية — خاصة بصفحة المعلم).

## ب) الدارك مود للأدمن
### 4. `lib/modules/admin/account/admin_account_page.dart`
- imports: `theme_controller.dart` + `widgets/section_header.dart`.
- بعد كرت الملف الشخصي مباشرة: `SectionHeader(title: 'المظهر', icon: Icons.dark_mode_rounded)` + حاوية بطاقة تحوي `Obx` > `SwitchListTile` («الوضع الليلي» / «خلفية داكنة مريحة للعين»، `value: themeCtrl.isDark`، `onChanged: themeCtrl.toggle`) — نسخ حر من `profile_page.dart:143-177`.
- الشل مهيأ أصلاً (`admin_shell.dart:45`) ⇒ لا تعديل آخر.

## ج) البناء والتسليم
1. `flutter analyze` ⇒ 0 أخطاء (13 info قديمة مقبولة).
2. رفع الإصدار: `versionCode 7` / `versionName 1.0.6` في `android/app/build.gradle.kts`.
3. `flutter build apk --release` + توقيع `apksigner` بـ`/home/mhmd/keys/scenter-release.jks`.
4. التثبيت في Waydroid مباشرة (إزالة القديم أولاً لو فشل التوقيع: `pm uninstall` ثم `waydroid app install`) — **بدون نسخة سطح المكتب**.
5. `git status` للتأكد أن التغييرات `mobile/` فقط.

## اختبارات حية على Waydroid
- إضافة محاضرة PDF برفع ملف من التطبيق.
- إضافة محاضرة فيديو (ضغط + رفع مع نسبة تقدّم) — مقاسات صغيرة للتجربة.
- تعديل محاضرة وتغيير النوع بينها.
- مفتاح الوضع الليلي في «حسابي» وثباته بعد إعادة التشغيل.
