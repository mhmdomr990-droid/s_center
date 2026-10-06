# خطة: نسبة المعلم في التفاصيل + عدّ «دورات» صحيح في حسابي (Flutter فقط)

## التشخيص (مكتمل — بلا تعديلات باك بقرار المستخدم)
1. **«1 دورات» في حسابي**: `profile_controller._loadTeacherStats()` يعد `stats['courses'].length` من `GET /teacher/stats` — وهذا الاستعلام `INNER JOIN` على المشتريات (`src/modules/teacher/service.ts:501-513`) ⇐ يحسب الدورات **المباعة فقط**. المعلم ذو دورتين باع في واحدة ⇐ 1.
2. **نسبة المعلم غير معروضة**: الواجهة لا تعرضها في أي مكان؛ وبياناتها متاحة حالياً **فقط** في تفاصيل الدورة (`getTeacherCourseById` يعيد `teacher_percent` ✓ — `service.ts:148`)، بينما قائمتا «دوراتي» وبطاقات اللوحة لا تردهان من الباك (بقرار: بلا تعديل باك).

## التعديلات (3 ملفات + الإصدار)

### 1) `mobile/lib/modules/student/profile/profile_controller.dart` — `_loadTeacherStats()`
- الاحتفاظ بـ `getStats()` لجلب `total_earned`.
- استبدال مصدر العدّ:
```dart
final r = await teacherProvider.getCourses();   // GET /teacher/courses
final total = r.data['meta']?['total'];
teacherCoursesCount.value = (total is num ? total.toInt()
    : (r.data['data'] is List ? (r.data['data'] as List).length : 0));
```
- `meta.total` = عدد كل دورات المعلّم فعلياً (`src/utils/pagination.ts:22` — `total: items.length`) — بلا اعتماد على حجم الصفحة.
- عند فشل أي من الطلبين: يبقى ما تحقق (سلوك صامت كالحالي).

### 2) `mobile/lib/modules/teacher/courses/teacher_course_detail_page.dart`
- إضافة شريحة في `Wrap` المعلومات (بجانب «مشتري»/«السعر»):
```dart
_buildInfoChip('نسبة المعلم: ${_percentLabel(course.teacherPercent)}%'),
```
- دالة مساعدة `_percentLabel` داخل الصفحة: تزيل الصفر الزائد (`'40.00'` ⇐ `40`، `'33.30'` ⇐ `33.3`، تُبقي ما دون ذلك).
- المصدر: `ctrl.currentCourse` الناتج عن `getCourseById` (البيانات متوفرة أصلاً).

### 3) الإصدار والتسليم (الحلقة المعتادة)
- `versionCode = 34` / `versionName = "1.0.33"`.
- `flutter analyze` ⇐ خط الأساس **22**.
- `flutter build apk --release` ← تو签名 فوري `apksigner` ⇐ `SIGNED_OK` + `CN=Student Center`.
- تثبيت على **هواوي** عبر adb (إن كانت متصلة؛ وإلا أبلغ المستخدم) ⇐ تحقق `34/1.0.33` ⇐ إطلاق.

## خارج النطاق (بقرار المستخدم — Flutter فقط)
- عرض النسبة في قائمة «دوراتي» وبطاقات لوحة التحكم: يتطلب سطرين في الباك (`listMyCourses` select + `mapCourseRow`، و/أو `getTeacherStats`) + نشر — يمكن لاحقاً.
- قسم «دوراتي» في لوحة التحكم يعرض الدورات المباعة فقط (نفس استعلام الإحصائيات) — لا يُلمَّس الآن.

## التحقق بعد التركيب
- حسابي (معلّم): عدد الدورات = العدد الحقيقي لكل دوراته.
- تفاصيل أي دورة للمعلم: شريحة «نسبة المعلم: …%» بقيمة صحيحة.
