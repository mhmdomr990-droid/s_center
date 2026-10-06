# حظر صوت التطبيق في تسجيل الشاشة — 1.0.26 (Waydroid)

## الطلب
تسجيل الشاشة: الشاشة السوداء مطلوبة (تعمل ✓) لكن **الصوت لا يُسجَّل** أيضاً.

## الحل
`AudioManager.setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_NONE)` —
يمنع أي تطبيق آخر (مسجّل النظام/MediaProjection/scrcpy) من التقاط صوت تشغيل التطبيق.
متحقق: `setAllowedCapturePolicy` موجود في `android-36/android.jar` + الثابت `ALLOW_CAPTURE_BY_NONE` ✓.

## التعديل (ملف واحد — كود أصلي فقط)
### `mobile/android/app/src/main/kotlin/com/scenter/mobile/MainActivity.kt`
```kotlin
package com.scenter.mobile

import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            getSystemService(AudioManager::class.java)
                ?.setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_NONE)
        }
    }
}
```
- يُضبط عند بدء التطبيق (سياسة عامة تبقى فعّالة) — لا حاجة لقناة MethodChannel ولا تعديل Dart.
- لا يؤثر على الميكروفون ولا على تشغيل التطبيق العادي.

## التسليم
1. bump `versionCode = 27`, `versionName = "1.0.26"`.
2. `flutter analyze` (0 error/warning، 22 info) → `flutter build apk --release` → توقيع `SIGNED_OK`.
3. تثبيت **Waydroid** (استيقاظ الجلسة إن لزم) ⇐ تحقق `dumpsys` = `27/1.0.26` ⇐ إطلاق.

## التحقق (بواسطة المستخدم)
تشغيل فيديو محاضرة ⇐ بدء تسجيل الشاشة ⇐:
- الشاشة تبقى سوداء ✓ (كما هي).
- الصوت **غير موجود** في التسجيل (سكوت) — إن كان التسجيل بميكروفون خارجي فالصوت لا يُحظر تقنياً (يجب تسجيل داخلي).

## احتمالات الفشل/بدائل إن لم يُحجب الصوت
- التسجيل من جانب لينكس (Host) خارج أندرويد ⇐ قد لا تُطبَّق السياسة — أخبرني بطريقة التسجيل لاختيار بديل.
- بديل احتياطي (لو لزم): استدعاء السياسة عند `ScreenGuard.protect()` عبر MethodChannel — نفس الأثر عملياً.
