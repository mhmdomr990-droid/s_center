# العودة لتفاصيل الدورة عند الخروج من ملء الشاشة — 1.0.28 (Waydroid)

## المشكلة
الخروج من ملء الشاشة يستقر على صفحة المحاضرة (بطاقة «عرض بملء الشاشة») بدل العودة لشاشة الإطلاق (تفاصيل الدورة).

## الحل — تغيير واحد في `video_fullscreen_page.dart`
في `_VideoFullscreenPageState.dispose` (يغطي كل طرق الخروج: السهم :141، تصغير :186، زر النظام/الإيماءة):
1. الإيقاف إن كان يعمل + `exitFullscreen()` (كما هو).
2. `WidgetsBinding.instance.addPostFrameCallback` ⇐:
   ```dart
   if (Get.currentRoute == AppRoutes.lectureView) Get.back<void>();
   ```
   أي إغلاق صفحة المحاضرة بعد ملء الشاشة — العودة لشاشة الإطلاق في كل المسارات الأربعة (course_detail / teacher_course_detail / admin content / downloads).
3. استيراد `app_routes.dart`.

**الحارس (`currentRoute == lectureView`)**: يمنع إغلاقاً خاطئاً لو كانت الصفحة مُزِيلة أصلاً (logout / offAll).

- PDF/نص: لا تتأثر (بلا fullscreen ⇐ بلا pop إضافي).
- بطاقة «عرض بملء الشاشة» تبقى كاحتياط إن لم يحدث auto-push (لا تظهر في المسار الطبيعي بعد هذا التغيير).

## التسليم
1. `versionCode = 29`، `versionName = "1.0.28"`.
2. `flutter analyze` ⇒ خط الأساس 22 info، 0 error/warning.
3. `flutter build apk --release` ثم **توقيع يدوي بعد البناء** (`apksigner` + `scenter-release.jks` + كلمات `key.properties`) ⇒ `SIGNED_OK` + تحقق `c9828eac` (شعبة StudentCenter).
4. تثبيت Waydroid: سحب APK عبر stdin إلى `/data/local/tmp` ثم `pm install -r` (طريقة مثبتة — `waydroid app install` لا يُطبِّق هنا) ⇐ `Success`.
5. تحقق `versionCode=28→29 / 1.0.27→1.0.28` ⇐ إطلاق `com.scenter.mobile`.

## التحقق
- فيديو ⇐ ملء الشاشة تلقائياً؛ خروج (الزر أو النظام) ⇐ تفاصيل الدورة مباشرة.
- من التحميلات/المعلم/الأدمن ⇐ يعود لتلك الشاشة.
- PDF/نص ⇐ يعود لصفحة المحاضرة (بلا pop إضافي).
