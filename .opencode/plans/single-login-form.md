# إلغاء تبويبات شاشة الدخول (طالب/معلم/إدارة) — 1.0.25 (Waydroid)

## الطلب
شاشة تسجيل الدخول: حذف التبويبات الثلاثة ⇐ نموذج واحد ⇐ التوجيه حسب نوع الحساب الداخل.

## الواقع (بحث)
- التوجيه بالدور **موجود أصلاً** في `login()` بعد نجاح الدخول: `isAdmin → AdminShell`، `isTeacher → TeacherShell`، وإلا `StudentShell` (`auth_controller.dart:108-114`).
- المانع الوحيد = فحص التطابق `loginRole.value != userData.role` (`:91-101`) — يُحذف.
- `loginRole` لا تُستخدم خارج `login_page.dart` و`auth_controller.dart` (تحققت).

## التعديلات (ملفان — تطبيق فقط)

### 1) `mobile/lib/modules/auth/login_page.dart`
- حذف صف التبويبات (`Obx` + Row الثلاث `_buildRoleTab`) + حذف دالة `_buildRoleTab` كاملة.
- العنوان `Obx` ⇐ ثابت: `Text('مرحباً بعودتك')`.
- العنوان الفرعي `Obx` ⇐ ثابت: `Text('سجّل دخولك للوصول لدوراتك')`.
- زر `Obx` ⇐ ثابت: `CustomButton(text: 'تسجيل الدخول', ...)`.
- شريط «ليس لديك حساب؟ سجّل الآن»: إزالة شرط `loginRole != 'STUDENT'` ⇐ يظهر دائماً (نموذج واحد — لا نعرف الدور مسبقاً، وشاشة التسجيل تُنشئ طالباً).

### 2) `mobile/lib/modules/auth/auth_controller.dart`
- حذف الحقل `final loginRole = 'STUDENT'.obs;` (`:27`).
- حذف كتلة فحص التطابق `if (loginRole.value != userData.role) {...}` كاملة (`:91-101`) — ومعها رسالة/snackbar المرتبطة بها.
- مسار النجاح `:108-114` يبقى كما هو (توجيه تلقائي حسب `userData.role`) ✓.

### 3) التسليم
- bump `versionCode = 26`, `versionName = "1.0.25"`.
- `flutter analyze` (0 error/warning) → `flutter build apk --release` → توقيع `SIGNED_OK`.
- تثبيت **Waydroid** (استيقاظ الجلسة إن STOPPED/FROZEN) ⇐ تحقق `26/1.0.25` ⇐ إطلاق.

## التحقق
- شاشة واحدة بلا تبويبات ⇐ دخول بحساب طالب → واجهة الطالب؛ معلم → واجهة المعلم؛ `asmaa` (إدارة) → واجهة الإدارة.
- رسالة الخطأ الموحدة (1.0.24) تعمل كما هي؛ رابط «سجّل الآن» ظاهر.

## خارج النطاق
- شاشة التسجيل (بلا تبويبات أصلاً)، الباك إند، اللوحة الويب.
