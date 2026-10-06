# رسالة خطأ موحّدة عند دخول كلمة مرور قصيرة — 1.0.24 (تثبيت Waydroid)

## المشكلة
إدخال كلمة مرور (<8) أو اسم مستخدم قصير في **شاشة الدخول** ⇐ الخادم يرد `400` بنص zod إنجليزي
`String must contain at least 8 character(s)` ⇐ `apiErrorMessage` يمرره كما هو
(سطر 29: أي رسالة خادم قصيرة غير مطابقة لأنماط معروفة تُعاد حرفياً) ⇐ الشريط الأحمر يعرض الإنجليزية.

## الحل (تعديل واحد — تطبيق فقط، بلا باك إند)
### `mobile/lib/modules/auth/auth_controller.dart` — كatch داخل `login()` (سطر ~115)
قبل:
```dart
} catch (e) {
  lastError.value = apiErrorMessage(e);
}
```
بعد:
```dart
} catch (e) {
  final status = e is DioException ? e.response?.statusCode : null;
  if (status == 400) {
    // رسائل تحقق الخادم (إنجليزية) → رسالة الدخول المعتادة
    lastError.value = 'اسم المستخدم أو كلمة المرور غير صحيحة';
  } else {
    lastError.value = apiErrorMessage(e);
  }
}
```
- `dio` مستورد أصلاً في الملف.
- يشمل كل حالات تحقق الخادم في الدخول (كلمة قصيرة، اسم قصير، أحرف غير مسموحة) برسالة واحدة كما طلب المستخدم.
- **لا يمسّ** `register()` (رسالة سنجلبار التسجيل) ولا أي شاشة أخرى — كلها تبقى كما هي.

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 25`, `versionName = "1.0.24"`.
3. `flutter build apk --release` ⇒ توقيع `apksigner` (key.properties + scenter-release.jks) ⇒ `verify` = SIGNED_OK.
4. تثبيت **Waydroid** (إن الحاوية FROZEN ⇐ `waydroid app launch` أولاً) ⇐ تحقق `dumpsys` (25/1.0.24) ⇐ إطلاق.

## التحقق
شاشة الدخول بكلمة <8 أو اسم قصير ⇐ الشريط الأحمر: **«اسم المستخدم أو كلمة المرور غير صحيحة»**
(بلا نص إنجليزي)؛ وكلمة صحيحة تعمل كالمعتاد؛ 401/429/شبكة تبقى برسائلها المعتادة.

## خارج النطاق (عند الطلب لاحقاً)
- نفس المشكلة في شاشة **التسجيل** (snackbar قد يعرض نص zod إنجليزياً).
- رسالة أوضح لـ403 «الحساب معطّل» عند الدخول.
