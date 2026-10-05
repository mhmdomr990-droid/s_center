# عنوان خادم ثابت — حذف الحقل من الشاشتين — 1.0.20 (تثبيت Waydroid)

## الطلب
حذف حقل «عنوان الخادم» من شاشتي تسجيل الدخول والتسجيل، وجعل العنوان ثابتاً تماماً غير قابل للمستخدم: **`http://143.244.151.183`** — كل محاولات الاتصال بهذا العنوان.

## التحقق (تم)
- `GET /` ⇒ 200 من نفس تطبيق Express (المنفذ 80).
- `POST /api/auth/login` و`/api/lectures/:id/stream-url` ⇒ ردود JSON من خادمنا ✓.
- الوسائط: الخادم يعيد `/media/play/:token` و `/media/download/:token` على الجذر (`src/app.ts:102-103`) — `MediaProvider.origin` يحذف `/api` من `baseUrl` ⇐ `http://143.244.151.183/media/...` ✓.
- ⇒ العنوان الثابت الداخلي = **`http://143.244.151.183/api`** (اصطلاح حالي: `baseUrl` ينتهي بـ`/api`).
- **ملاحظة حرجة:** `_normalizeBase` الحالية تضيف `:3000` تلقائياً لأي IPv4 — لذلك تُحذف الآلية كاملاً لا تُعدَّل.

## التعديلات (5 ملفات — mobile فقط)

### 1) `mobile/lib/data/providers/api_client.dart`
```dart
// عنوان الخادم الثابت — لا يُدخل من الواجهة ولا يتغير
static const String defaultBaseUrl = 'http://143.244.151.183/api';
static String baseUrl = defaultBaseUrl;
```
+ حذف: `overrideKey`، `applyBaseUrl()` (لا مستخدم بعد الحذف).

### 2) `mobile/lib/main.dart`
- حذف كتلة قراءة `prefs.getString(ApiClient.overrideKey)` (سطور ~60-68) — القديم `api_base_url_v1` يُتجاهَل نهائياً (يبقى في prefs بلا قارئ — لا ضرر).
- حذف `import 'package:shared_preferences/shared_preferences.dart';` إن صار غير مستخدم.

### 3) `mobile/lib/modules/auth/auth_controller.dart` — حذف آلية العنوان
- `final ipCtrl = TextEditingController(text: ApiClient.baseUrl);` (سطر 39)
- `ipCtrl.dispose();` في `onClose`
- `static final RegExp _ipv4` + دالة `_normalizeBase` كاملة
- دالة `_applyServerHost` كاملة + الاستدعاءان `if (!await _applyServerHost()) return;` في `login()` و`register()`
- فرع `if (ApiClient.baseUrl.isEmpty) {...}` في `checkAuth()` (سطور ~249-254) — مستحيل بعد التثبيت
- `import 'package:shared_preferences/shared_preferences.dart';` إن صار غير مستخدماً
- يبقى `_apiClient` (يستخدمه `AuthProvider(_apiClient)` سطر 117) — والحقول الأخرى (`_syncScope`/`_clearScope`...) لم تُمس.

### 4) `mobile/lib/modules/auth/login_page.dart`
حذف:
```dart
const SizedBox(height: 16),
CustomTextField(
  labelText: 'عنوان الخادم',
  prefixIcon: Icons.dns_outlined,
  controller: ctrl.ipCtrl,
  keyboardType: TextInputType.url,
),
```
(شريط الخطأ الأحمر `lastError` يبقى — له `margin top:16` مستقل.)

### 5) `mobile/lib/modules/auth/register_page.dart`
حذف حقل «عنوان الخادم» نفسه (آخر عنصر في عمود النموذج).

## لا يتغير
- `admin_account_page.dart:117` يعرض `SelectableText(ApiClient.baseUrl)` — سيعرض العنوان الثابت.
- `MediaProvider`، وضع غير المتصل، كل مناطق `apiErrorMessage`.
- الباك إند لا يُمس إطلاقاً.

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 21`, `versionName = "1.0.20"`.
3. `flutter build apk --release` ⇒ توقيع (`apksigner` + `mobile/android/key.properties` + `/home/mhmd/keys/scenter-release.jks`) ⇒ `verify` = SIGNED_OK.
4. تثبيت **Waydroid** فقط: إن كانت الجلسة متوقفة ⇒ `nohup waydroid session start >/tmp/opencode/waydroid_session.log 2>&1 &` + انتظار RUNNING ⇒ `waydroid app install <apk>` ⇒ تحقق `sudo waydroid shell dumpsys package com.scenter.mobile` (21/1.0.20) ⇒ `waydroid app launch com.scenter.mobile`.

## التحقق
- شاشة الدخول: لا حقل «عنوان الخادم» إطلاقاً (ولا في التسجيل).
- الدخول بحساب صحيح من Waydroid ⇐ الاتصال بـ`143.244.151.183` فعلياً (أسرفر الإنتاج).
- رفع/تشغيل فيديو ⇐ `/media/play/...` على نفس العنوان.
- حساب إداري في تبويب الطالب ⇐ رسالة 401 القياسية (1.0.19 كما هي).
