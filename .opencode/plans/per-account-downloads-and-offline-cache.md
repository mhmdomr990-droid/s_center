# عزل تنزيلاتي + كاش الدورات لكل حساب — 1.0.17 (تثبيت هواوي)

## المشكلة
- `download_manager.dart`: مفتاح سجل عالمي واحد `lecture_downloads_v1` + مجلد `downloads/` واحد بلا هوية مستخدم ⇒ طالب B يرى تنزيلات طالب A ويشغّلها (AES مفتاح الجهاز).
- `offline_cache.dart`: مفتاحان عالميان (`offline_catalog_v1`, `offline_lectures_v1_<courseId>`) ⇒ اشتراكات A تظهر لـB في الوضع غير المتصل.
- `DownloadManager` خدمة دائمة تُحمَّل مرة (`main.dart:78`) وتبقى بين جلسات الدخول.

## نقاط هوية المستخدم (مُتحقَّق)
- `AuthController.checkAuth()` سطر 253 (فرع `/me`) و276 (فرع الكاش) — الإقلاع عبر splash.
- `AuthController.login()` نجاح ~سطر 152، `register()` ~سطر 218.
- `AuthController.logout()` سطر 293-303 + فرع 401 في `checkAuth` سطر 267.
- `UserModel.id` متوفر؛ `unawaited` من `dart:async`.

---

## التعديلات (3 ملفات)

### 1) `mobile/lib/data/services/download_manager.dart`

**أ. ثوابت + حقل النطاق:**
```dart
// بدلاً من: static const _prefsKey = 'lecture_downloads_v1';
static const _prefsKeyLegacy = 'lecture_downloads_v1';
static const _prefsKeyPrefix = 'lecture_downloads_v1__u';

int? _userId;
String? get _scopedKey => _userId == null ? null : '$_prefsKeyPrefix$_userId';
```

**ب. دوال النطاق (تُضاف بعد onInit):**
```dart
Future<void> scopeToUser(int userId) async {
  if (_userId == userId) return;
  _userId = userId;
  records.clear();
  await _clearTempPlaintext();
  await _migrateLegacyScope();
  await _load();
}

Future<void> clearScope() async {
  _userId = null;
  records.clear();
  await _clearTempPlaintext();
}
```

**ج. ترحيل القديم (مرة واحدة):**
```dart
Future<void> _migrateLegacyScope() async {
  try {
    final scoped = _scopedKey;
    if (scoped == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(scoped)) return;
    final raw = prefs.getString(_prefsKeyLegacy);
    if (raw == null || raw.isEmpty) return;
    final legacyDir = await _legacyDownloadsDir();
    if (await legacyDir.exists()) {
      final userDir = await _downloadsDir();
      await for (final entity in legacyDir.list()) {
        if (entity is! File) continue;
        try {
          final target = File('${userDir.path}/${entity.uri.pathSegments.last}');
          if (!await target.exists()) await entity.rename(target.path);
        } catch (_) {}
      }
    }
    await prefs.setString(scoped, raw);
    await prefs.remove(_prefsKeyLegacy);
  } catch (e) { debugPrint('DOWNLOADS_MIGRATE_ERR $e'); }
}
```

**د. تنظيف plaintext عند تبديل النطاق/الخروج:**
```dart
Future<void> _clearTempPlaintext() async {
  try {
    final support = await getApplicationSupportDirectory();
    final tmp = Directory('${support.path}/tmp');
    if (!await tmp.exists()) return;
    await for (final entity in tmp.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('play_') || name.startsWith('stream_') || name.startsWith('raw_')) {
        try { await entity.delete(); } catch (_) {}
      }
    }
  } catch (_) {}
}
```

**هـ. تعديل `_load`:** أول سطر داخل try: `final key = _scopedKey; if (key == null) { records.clear(); return; }` ثم `prefs.getString(key)` بدل `_prefsKey`؛ وفي `else` أضف `records.clear()`.

**و. تعديل `_save`:** `final key = _scopedKey; if (key == null) return;` ثم `prefs.setString(key, ...)`.

**ز. تعديل `cleanupExpired`:** `final key = _scopedKey; if (key == null) return;` ثم `prefs.getString(key)` و`prefs.setString(key, jsonEncode(keep))`.

**ح. تعديل `_downloadsDir`:**
```dart
final base = _userId == null
    ? '${support.path}/downloads'          // مجلد قديم مشترك (للترحيل فقط)
    : '${support.path}/downloads/u$_userId';
```
+ دالة جديدة:
```dart
Future<Directory> _legacyDownloadsDir() async {
  final support = await getApplicationSupportDirectory();
  return Directory('${support.path}/downloads');
}
```

**ط. حارس في `downloadLecture`:** بعد فحص `_offlineSupported`: `if (_userId == null) throw StateError('لا يوجد حساب نشط');`

> `decryptToTemp`/`recordFor`/`isDownloaded` لا تحتاج تغييراً — تعتمد `records` الفارغة خارج النطاق.
> **ملاحظة مقصودة:** `downloads/u<id>/` تحتوي مجلدات `u*` داخل مجلد `downloads/` — `_legacyDownloadsDir` عند الترحيل يتخطى غير `File` تلقائياً ✓.

### 2) `mobile/lib/data/services/offline_cache.dart`

```dart
static int? scope;

static String get _catalogKey => scope == null ? '' : 'offline_catalog_v1__u$scope';
static String _lecturesKey(int courseId) => 'offline_lectures_v1__u${scope}_$courseId';
```
- في `saveCatalog`/`saveCourseDetail`: `if (scope == null) return;` أول سطر.
- في `loadCatalog`: إن كان `_catalogKey` فارغاً ⇒ return null؛ وإن كان المفتاح المُنطَّق غائباً والمفتاح القديم `offline_catalog_v1` موجوداً ⇒ **نسخة إليه (ترحيل) ثم حذف القديم** ثم إرجاعها.
- في `loadCourseDetail(courseId)`: نفس الآلية مع المفتاح القديم `offline_lectures_v1_$courseId` (تصادم مستحيل: القديم لاحقته أرقام فقط والمنطَّق يحوي `__u`).
- `courses_controller.dart` **لا يُعدَّل** — نداءاته الثابتة تعمل بنطاق تلقائي.

### 3) `mobile/lib/modules/auth/auth_controller.dart`

- إسما imports: `dart:async` (unawaited)، `../../data/services/download_manager.dart`، `../../data/services/offline_cache.dart`.
- helper خاص:
```dart
void _syncScope(UserModel u) {
  unawaited(Get.find<DownloadManager>().scopeToUser(u.id));
  unawaited(OfflineCache.setScope(u.id));
}
```
  (وتصحيح: `OfflineCache.setScope` تُنفَّذ كـ`unawaited` كذلك — الدالة async.)
- **نقاط الاستدعاء:**
  | الموضع | النداء |
  |---|---|
  | `checkAuth()` بعد `user.value = userData` (253) | `_syncScope(userData)` |
  | `checkAuth()` فرع الكاش بعد `user.value = cached` (276) | `_syncScope(cached)` |
  | `login()` بعد `user.value = userData` (~152) | `_syncScope(userData)` |
  | `register()` بعد `user.value = userData` (~218) | `_syncScope(userData)` |
  | `logout()` بعد `clearAll()` (298) | `unawaited(Get.find<DownloadManager>().clearScope()); unawaited(OfflineCache.setScope(null));` |
  | `checkAuth()` فرع 401 بعد `clearAll()` (267) | نفس نداءات logout |

## السلوك بعد التنفيذ
- A يحمّل ⇒ B يدخل ⇒ «تنزيلاتي» فارغة + كاش الدورات صفر (يجلب من الشبكة) + لا ملفات play قديمة ⇒ عودة A ⇒ سجلاته وكاتشه عادا (كانا محفوظين بمفاتيحه).
- أول دخول بعد التحديث يرث التنزيلات/الكاش القديم المجمّع (ترحيل مرة واحدة ثم حذف القديم).
- بلا تسجيل دخول: لا قراءة ولا كتابة إطلاقاً.

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info قديمة).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 18`, `versionName = "1.0.17"`.
3. `flutter build apk --release` ⇒ توقيع (`apksigner` ببيانات `mobile/android/key.properties` + `/home/mhmd/keys/scenter-release.jks`) ⇒ `verify` = SIGNED_OK.
4. تثبيت **هواوي فقط**: `adb -s H9YNW20A29001562 install -r` + `dumpsys package com.scenter.mobile` (18/1.0.17) + `monkey ... LAUNCHER`.
5. نسخة سطح مكتب: `~/Desktop/s_center_1.0.17_release.apk`.

## التحقق اليدوي (للمستخدم)
1. حساب A ← تنزيل محاضرة ← خروج ← دخول B ⇒ «تنزيلاتي» فارغة والدورات تُجلَب من الشبكة.
2. عودة A ⇒ تنزيلاته موجودة وتعمل دون إنترنت.
