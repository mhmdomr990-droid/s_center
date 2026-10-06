# إلغاء طريقة الدفع «تحويل مكتب» — 1.0.22 (تثبيت Waydroid)

## الطلب
إلغاء طريقة الدفع TRANSFER_OFFICE («تحويل مكتب») — مع إبقاء واجهة الاختيار **بشريحة واحدة** (Sham Cash).

## ما يتغير (ملف واحد — mobile فقط)

### `mobile/lib/modules/student/wallet/topup_page.dart` (≈ سطر 55-60)
قبل:
```dart
Obx(() => Row(
  children: [
    Expanded(child: _buildMethodChip(ctrl, 'SHAM_CASH', 'Sham Cash', Icons.account_balance_wallet_rounded)),
    const SizedBox(width: 12),
    Expanded(child: _buildMethodChip(ctrl, 'TRANSFER_OFFICE', 'تحويل مكتب', Icons.store_rounded)),
  ],
)),
```
بعد:
```dart
Obx(() => Row(
  children: [
    Expanded(child: _buildMethodChip(ctrl, 'SHAM_CASH', 'Sham Cash', Icons.account_balance_wallet_rounded)),
  ],
)),
```
- يبقى عنوان «طريقة الدفع» + الشريحة + `_buildMethodChip` + `selectedMethod` في الكونترولر (تبقى `SHAM_CASH` دائماً).

## ما لا يتغير
- `topup_controller.dart`: `selectedMethod = 'SHAM_CASH'` و `method: selectedMethod.value` — يُرسل `SHAM_CASH` حتماً (لا يوجد مصدر تغيير آخر).
- `admin/topups/topup_requests_page.dart:178`: عرض تسمية «تحويل مكتب» للطلبات القديمة يبقى.
- **الباك إند كاملاً دون تغيير**: القيمة `TRANSFER_OFFICE` تبقى في enum/قاعدة البيانات (طلبات تاريخية) — حذفها من enum يكسر الصفوف القديمة.

## التسليم
1. `flutter analyze` ⇒ 0 error/warning (22 info).
2. bump `mobile/android/app/build.gradle.kts`: `versionCode = 23`, `versionName = "1.0.22"`.
3. `flutter build apk --release` ⇒ توقيع (`apksigner` + `mobile/android/key.properties` + `/home/mhmd/keys/scenter-release.jks`) ⇒ `verify` = SIGNED_OK.
4. تثبيت **Waydroid**: إن الحاوية FROZEN ⇐ `waydroid app launch com.scenter.mobile` أولاً ⇐ `waydroid app install <apk>` ⇐ تحقق dumpsys (23/1.0.22) ⇐ إعادة إطلاق.

## التحقق
- شاشة شحن الرصيد: شريحة واحدة فقط «Sham Cash» (بلا «تحويل مكتب»).
- إرسال طلب شحن ⇐ يظهر في لوحة الأدمن بطريقة Sham Cash.
- طلبات الأدمن القديمة بطريقة «تحويل مكتب» تُعرض كما هي.
