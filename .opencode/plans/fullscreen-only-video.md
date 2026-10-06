# الفيديو في ملء الشاشة فقط + إلغاء السابق/التالي — 1.0.27 (Waydroid)

## الطلب
1. عرض الفيديو **فقط** بوضع ملء الشاشة (إلغاء الوضع العادي/المضمن).
2. إلغاء زرّي «السابق/التالي».

## البنية الحالية (بحث)
- `lecture_view_page.dart`:
  - `_VideoSection` (سطر ~663): تحميل / خطأ / موضع مؤقت «اضغط لتشغيل» / **مشغّل مضمَّن** (AspectRatio + أزرار + `VideoSeekBar` + أيقونة ملء الشاشة `Get.to(VideoFullscreenPage)`).
  - صف «السابق/التالي» (~619-647) لكل أنواع المحاضرات + دوال `previousLecture/nextLecture/hasPrevious/hasNext` + مستمع `ever(currentIndex)` في `onInit`.
- `video_fullscreen_page.dart`: مسار مستقل — `initState → enterFullscreen()` (أفقي + immersive)، `dispose → exitFullscreen()` (رجوع عمودي)؛ يعرض تحميل/خطأ/إعادة محاولة/أزرار تحكم؛ **بلا السابق/التالي** ✓.
- `VideoSeekBar` (عام، سطر 852) — لا يُستخدم إلا في المشغّل المضمَّن.

## التعديلات (ملفان: `lecture_view_page.dart` أولاً)

### 1) `LectureController`
- حقل جديد `bool _autoFsPushed = false;`
- في `_loadPlayer()` بعد فحص `if (!lecture.isVideo) return;`:
  - إن `!isFullscreen.value` ⇐ إعادة تعيين `_autoFsPushed = false` (يسمح بإعادة الدفع بعد الخروج/فشل).
  - إن `!isFullscreen.value && !_autoFsPushed` ⇐ `_autoFsPushed = true` + `addPostFrameCallback` ⇐ `Get.to(() => VideoFullscreenPage(ctrl: this))` — **يدخل ملء الشاشة تلقائياً فور فتح فيديو المحاضرة** (صفحة الملء تُظهر التحميل/الخطأ/التحكم بنفسها).
- دالة جديدة `openFullscreenVideo()`:
  - إذا لا مشغّل أو هناك خطأ ⇐ `_loadPlayer(autoplay: true)` (يدفع ملء الشاشة تلقائياً).
  - وإلا ⇐ `Get.to(() => VideoFullscreenPage(ctrl: this))` مباشرة (المشغّل حيّ).
- حذف: `previousLecture`، `nextLecture`، `hasPrevious`، `hasNext` + مستمع `ever(currentIndex)` (يبقى `currentIndex`/`currentLecture` للتقدم).

### 2) `_VideoSection`
- الإبقاء على فرعي التحميل والخطأ (زر الخطأ ⇐ `ctrl.openFullscreenVideo()` بدل `retry` فقط).
- استبدال «موضع مؤقت + المشغّل المضمَّن كاملاً» (بما فيه `VideoPlayer`، `VideoSeekBar`، أزرار التشغيل، أيقونة ملء الشاشة) ببطاقة واحدة: أسود + أيقونة `play_circle` + زر **«عرض بملء الشاشة»** ⇐ `ctrl.openFullscreenVideo()`.
- حذف صف السابق/التالي من شجرة الواجهة.
- حذف كلاس `VideoSeekBar` (صار بلا استخدام).

### 3) `video_fullscreen_page.dart`
- في `_VideoFullscreenPageState.dispose`: بعد `exitFullscreen()` ⇐ إن كان يعمل ⇐ إيقاف التشغيل (`togglePlay`) — **لا صوت مخفي** بعد العود للشاشة العادية (متوافق مع تفضيل «إيقاف فقط» سابقاً).

## التسليم
1. bump `versionCode = 28`, `versionName = "1.0.27"`.
2. `flutter analyze` (0 error/warning، 22 info).
3. `flutter build apk --release` → توقيع `SIGNED_OK`.
4. تثبيت **Waydroid** ⇐ تحقق `28/1.0.27` ⇐ إطلاق.

## التحقق
- فتح محاضرة فيديو ⇐ يدور تلقائياً لملء الشاشة ويعرض التحكم.
- الخروج من ملء الشاشة ⇐ لا مشغّل مضمَّن + لا سابق/تالي + بطاقة «عرض بملء الشاشة» تعيد للدخول + لا صوت مستمر.
- محاضرة PDF/نص ⇐ بلا السابق/التالي (المحتوى فقط).

## خارج النطاق
- شاشة الملء الكامل نفسها (تعمل كما هي)، التقدم/مواضع المشاهدة، مسارات الأدمن/المعلم (تستخدم الصفحة نفسها وتكون ملء الشاشة تلقائياً).
