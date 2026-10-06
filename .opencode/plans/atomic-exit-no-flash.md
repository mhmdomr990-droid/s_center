# إزالة وميض صفحة المحاضرة عند الخروج من ملء الشاشة — 1.0.29 (Waydroid)

## المشكلة
الخروج الحالي من ملء الشاشة = `Get.back()` (يزيل ملء الشاشة فقط) ثم `postFrame` pop إضافي لصفحة المحاضرة — أي أن صفحة المحاضرة **تظهر أثناء انتقال الخروج وللإطار التالي** ⇐ "جزء من الثانية" ثم تختفي.

## الحل (ملف واحد: `video_fullscreen_page.dart`) — إغلاق ذرّي في استدعاء واحد

### 1) دالة خروج واحدة `_exit()`
```dart
void _exit() {
  // أوقف التشغيل والكنترولر حيّ (لا صوت مخفي)
  if (widget.ctrl.isPlaying.value) unawaited(widget.ctrl.togglePlay());
  // ملء الشاشة + صفحة المحاضرة = popUntil واحد ⇐ لا وميض
  if (Get.previousRoute == AppRoutes.lectureView) {
    Get.close(2);
  } else {
    Get.close(1); // احتياطي: صفحة المحاضرة ليست تحتنا
  }
}
```
- مصدر GetX (`get-4.7.3`): `Get.close(times)` = `popUntil(count++ == times)` ⇐ يزيل **N مساراً في نفس اللحظة** (بدون انتقال وسيط يكشف صفحة المحاضرة) و**بلا فحص PopScope** (programmatic pop).
- الحارس `Get.previousRoute == AppRoutes.lectureView`: ما نغلق ما لا يخصّنا (logout/offAll).

### 2) استبدال أزرار الخروج (:149,:194)
`Get.back<void>()` ⇐ `_exit()` (سهم الرجوع العلوي + أيقونة تصغير).

### 3) زر النظام/الإيماءة — `PopScope` حول `Scaffold`
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) { if (!didPop) _exit(); },
  child: Scaffold(...),
)
```
- Flutter 3.47.1 ⇐ `onPopInvokedWithResult` متاح بلا deprecation (لا يضيف analyzer infos).
- يغطي زر الرجوع في أندرويد والإيماءة (predictive back).

### 4) `dispose` المُبسَّط
- **حذف** كتلة `postFrame + Get.back` (مصدر الوهج — صارت عبر `_exit`).
- الإبقاء على `exitFullscreen()` فقط (استعادة الاتجاه — SystemChrome آمن بعد إغلاق الصفحة).
- نقل الإيقاف (pause) إلى `_exit` قبل الإغلاق ⇐ `togglePlay` يفحص `videoController == null` أصلاً (آمن).

### 5) لا تغييرات أخرى
- PDF/نص: بلا fullscreen ⇐ بلا تغيير.
- دخول تلقائي ملء الشاشة والتقدّم/الحفظ (`LectureController.onClose` عند `Get.close(2)`) كما هو.

## التسليم
1. `versionCode = 30`، `versionName = "1.0.29"`.
2. `flutter analyze` ⇐ خط الأساس **22 info** (0 error/warning).
3. `flutter build apk --release` ⇐ ثم **توقيع يدوي بعد البناء** (`apksigner` + `scenter-release.jks`) ⇐ تحقق شعبة `c9828eac` (لا تكرار فخاخ Debug).
4. Waydroid: إن وُجدت الجلسة متوقفة ⇐ `nohup waydroid session start` + انتظار `boot_completed=1` ⇐ سحب APK عبر stdin إلى `/data/local/tmp` ⇐ `pm install -r` ⇐ `Success`.
5. تحقق `versionCode=30 / versionName=1.0.29` ⇐ إطلاق `com.scenter.mobile`.

## التحقق
- خروج بأي طريقة (السهم/تصغير/زر النظام/الإيماءة) ⇐ الانتقال مباشرة لشاشة تفاصيل الدورة **بلا ظهور صفحة المحاضرة إطلاقاً**.
- إيقاف الفيديو عند الخروج + حفظ التقدّم.
- PDF/نص ⇐ يعود لصفحة المحاضرة عادياً (بلا وميض إضافي — بلا fullscreen أصلاً).
