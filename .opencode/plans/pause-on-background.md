# إيقاف الفيديو عند دخول الخلفية — 1.0.30 (Waydroid)

## الحالة الحالية
`didChangeAppLifecycleState` في `lecture_view_page.dart:141` عند `paused/inactive/detached` يحفظ **الموضع فقط** ولا يوقف التشغيل ⇐ الصوت يستمر في الخلفية (كما أكّدت المعاينة).

## المطلوب (بقرار المستخدم)
- دخول الخلفية ⇐ **إيقاف** الفيديو فوراً + حفظ الموضع (كما هو).
- العودة للمقدمة ⇐ **لا استئناف تلقائي** — المستخدم يدوس تشغيل بنفسه من نفس الموضع.

## التعديل — ملف واحد `lecture_view_page.dart` (الكنترولر فقط)

### في `didChangeAppLifecycleState`
الإبقاء على حفظ الموضع الحالي كما هو، وإضافة الإيقاف **عند `paused` و`detached` فقط** (وليس `inactive`):
```dart
if (state == AppLifecycleState.paused ||
    state == AppLifecycleState.detached) {
  unawaited(videoController?.pause());   // بلا صوت في الخلفية
}
```
- `inactive` يبقى لحفظ الموضع فقط: يشتعل عند هبوط لوحة الإشعارات/نوافذ الأذونات ⇐ إيقافه سيكون مزعجاً (يسحب الإشعار ⇐ يوقف الفيديو).
- `paused` يغطي: زر الرئيسية، مبدّل التطبيقات، إطفاء الشاشة.
- يعمل سواء كان الفيديو في ملء الشاشة أو في الشاشة العادية (نفس الكنترولر + نفس المراقب).
- `videoController?.pause()` آمن لو لا مشغّل (PDF/نص/لم يبدأ).

## التسليم
1. `versionCode = 31`، `versionName = "1.0.30"`.
2. `flutter analyze` ⇐ خط الأساس **22 info**.
3. `flutter build apk --release` ⇐ ثم توقيع يدوي (`apksigner` + `scenter-release.jks`) ⇐ شعبة `c9828eac`.
4. Waydroid: إن كانت الجلسة متوقفة ⇐ `nohup waydroid session start` + انتظار `boot_completed=1` ⇐ سحب عبر stdin ⇐ `pm install -r` ⇐ `Success`.
5. تحقق `versionCode=31 / 1.0.30` ⇐ إطلاق.

## التحقق
- تشغيل فيديو ⇐ زر الرئيسية/إطفاء الشاشة ⇐ الصوت يتوقف فوراً + الموضع محفوظ.
- العودة ⇐ لا استئناف تلقائي — زر التشغيل يكمل من نفس الموضع.
- لوحة الإشعارات (سحب) ⇐ **لا** يوقف الفيديو.
- PDF/نص ⇐ بلا تغيير.
