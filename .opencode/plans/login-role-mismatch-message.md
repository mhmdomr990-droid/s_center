# إخفاء رسالة نوع الحساب في تسجيل الدخول — 1.0.19 (تثبيت Waydroid)

## الطلب
عند إدخال حساب إداري (أو معلم) في تبويب الطالب: لا تظهر رسالة «هذا حساب إداري — اختر تبويب إداري»؛ بل تظهر الرسالة القياسية لخطأ بيانات الدخول. بقاء بقية رسائل الخادم كما هي.

## التشخيص
- المصدر الوحيد: `mobile/lib/modules/auth/auth_controller.dart` داخل `login()` (~سطور 155-164):
```dart
const roleLabels = {'STUDENT': 'طالب', 'TEACHER': 'معلم', 'ADMIN': 'إداري'};
if (loginRole.value != userData.role) {
  final accountRole = roleLabels[userData.role] ?? userData.role;
  Get.snackbar('خطأ', 'هذا حساب $accountRole — اختر تبويب $accountRole', ...);
  return;   // قبل saveToken — لا أثر على الحالة
}
```
- فحص خلفي فقط: الخادم يعيد 200 + token + نوع الحساب، والتطبيق يرفض بعده.
- الحالات الثلاث (إداري/معلم/طالب في تبويب خاطئ) تمر بنفس الفرع.

## التعديل (ملف واحد: auth_controller.dart)
```dart
if (loginRole.value != userData.role) {
  Get.snackbar('خطأ', 'اسم المستخدم أو كلمة المرور غير صحيحة',
      backgroundColor: Colors.red, colorText: Colors.white);
  return;
}
```
1. استبدال النص بالرسالة القياسية لخطأ 401 الموجودة في `api_exception.dart` (موافقة المستخدم).
2. حذف `roleLabels` و`accountRole` (تصبح غير مستخدمة ⇒ تحذير analyzer).
3. الإبقاء على `return` قبل `saveToken`.

## لا يتغير
- `api_exception.dart` وكل رسائل الخادم (رصيد غير كافٍ، جهاز آخر، 4xx/5xx...) — لم تُمس.
- شاشة التسجيل/تبويب المعلم — ليس لها هذا الفرع.

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 20`, `versionName = "1.0.19"`.
3. `flutter build apk --release` ⇒ توقيع (`apksigner` + `mobile/android/key.properties` + `/home/mhmd/keys/scenter-release.jks`) ⇒ `verify` = SIGNED_OK.
4. تثبيت **Waydroid** فقط: `waydroid app install -r <apk>` (أو `waydroid app install`) + `waydroid shell dumpsys package com.scenter.mobile` (20/1.0.19) + `waydroid app launch com.scenter.mobile`.
   - إن كانت الجلسة متوقفة: `nohup waydroid session start >/tmp/opencode/waydroid_session.log 2>&1 &` ثم انتظار `waydroid status` = RUNNING.

## التحقق
- تبويب الطالب + حساب admin/admin1234 ⇒ سناك «خطأ: اسم المستخدم أو كلمة المرور غير صحيحة» (بلا «اختر تبويب»).
- كلمة مرور خاطئة مع حساب طالب ⇒ نفس الرسالة (كما قبل).
- رسالة خطأ من الخادم (رصيد غير كافٍ مثلاً) ⇒ تبقى كما هي.
