# تقصير رسائل الأخطاء للمستخدم — 1.0.18 (تثبيت هواوي)

## السياق
- صورة المستخدم: نافذة/سناك بار يعرض **نص Dio الخام** كامل (`DioException [bad response] ... 404 ... developer.mozilla.org`).
- بحث شامل (grep + `git log -S` كل الفروع): النص `فشل التحديث: $e` **غير موجود** في أي إصدار مُلتزم — الصورة من APK قديم على جهاز قديم؛ لكن 1.0.17 الحالية بها 3 مصادر لرسائل طويلة.
- معتمد من المستخدم + سؤاله: «حذف نافذة الدخول» = نافذة `AlertDialog` «تفاصيل فشل الاتصال» فقط (شاشة الدخول + الشريط الأحمر يبقيان).

## التعديلات (3 ملفات)

### 1) `mobile/lib/data/providers/api_exception.dart`
**أ. استيراد:** أضف `import 'package:flutter/foundation.dart';` (لـ`kDebugMode`).

**ب. قصّ رسائل الخادم الطويلة** — بعد استخراج `serverMsg` مباشرة:
```dart
// نص خادم طويل (أكثر من 120 حرفاً) لا يصل للمستخدم — نتجاهله
// ونعتمد الرسالة المختصرة حسب الحالة أدناه
if (serverMsg != null && serverMsg.length > 120) serverMsg = null;
```

**ج. فرع الشبكة (سطور 46-59)** — قصير في release + تفاصيل debug فقط:
```dart
if (error.type == DioExceptionType.connectionTimeout ||
    error.type == DioExceptionType.sendTimeout ||
    error.type == DioExceptionType.receiveTimeout ||
    error.type == DioExceptionType.connectionError ||
    error.type == DioExceptionType.unknown) {
  // المستخدم يرى سطراً واحداً فقط — والتفاصيل (العنوان/السبب/النوع/
  // الفحص) تبقى حصراً في نسخ التطوير للتشخيص
  const short = 'تعذر الاتصال بالخادم، تحقق من الشبكة';
  if (!kDebugMode) return short;
  final origin = error.requestOptions.uri.origin;
  final where = origin.isEmpty ? '' : '\nالعنوان: $origin';
  var cause = error.error?.toString() ?? '';
  if (cause.length > 160) cause = cause.substring(0, 160);
  final why = cause.isEmpty ? '' : '\nالسبب: $cause';
  final hint = _netHint(cause);
  final hintLine = hint.isEmpty ? '' : '\n$hint';
  return '$short$where$why\nالنوع: ${error.type.name}$hintLine';
}
```
- `_netHint` تبقى مستخدمة (debug) — لا dead code.

### 2) `mobile/lib/modules/auth/auth_controller.dart` (~سطور 180-192 في login catch)
حذف نافذة الحوار كاملة — يبقى `lastError.value = msg` فقط:
```dart
} catch (e) {
  lastError.value = apiErrorMessage(e);
} finally {
```
(حذف `Get.dialog<void>(AlertDialog(title: 'تفاصيل فشل الاتصال', content: SelectableText(msg)...))`.)

### 3) `mobile/lib/widgets/download_lecture_button.dart:76`
```dart
// بدلاً من: content: Text('فشل التحميل: $e'),
content: Text(apiErrorMessage(e, fallback: 'فشل التحميل')),
```
+ استيراد `../../data/providers/api_exception.dart`.
(آخر تسريب خام `$e` في الواجهة.)

## النتيجة
| الحالة | قبل | بعد (release) |
|---|---|---|
| شبكة/مهلة/DNS | 5 أسطر (عنوان+سبب+نوع+فحص) | «تعذر الاتصال بالخادم، تحقق من الشبكة» |
| نص خادم طويل | كما هو | مُقصوص ← رسالة الحالة القصيرة |
| 404 | (أو نص قديم خام) | «العنصر المطلوب غير موجود» |
| فشل التحميل خام | `DioException...` | «فشل التحميل» / رسالة قصيرة |
| تفاصيل تشخيص | للمستخدم | `kDebugMode` فقط |

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 19`, `versionName = "1.0.18"`.
3. `flutter build apk --release` ⇒ توقيع (`apksigner` + `mobile/android/key.properties` + `/home/mhmd/keys/scenter-release.jks`) ⇒ `verify` = SIGNED_OK.
4. تثبيت **هواوي**: `adb -s H9YNW20A29001562 install -r` + `dumpsys` (19/1.0.18) + `monkey ... LAUNCHER`.
5. نسخة سطح المكتب: `~/Desktop/s_center_1.0.18_release.apk`.

## التحقق
- إدخول IP خاطئ في شاشة الدخول ⇒ شريط أحمر بسطر واحد فقط (بلا نافذة منبثقة).
- سحب-للتحديث في أي شاشة بلا شبكة ⇒ سناك بسطر واحد.
- زر التحميل بلا اتصال ⇒ «تعذر الاتصال بالخادم، تحقق من الشبكة».
