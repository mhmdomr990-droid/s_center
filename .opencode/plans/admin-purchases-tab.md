# خطة: تبويب «عمليات الشراء» للأدمن (زر في شريط العنوان)

## القرار
- **Flutter فقط** (بلا أي تعديل باك — بموافقة صريحة).
- **الموضع**: زر `receipt_long_outlined` في شريط عنوان تبويب **«طلبات الشحن»** (`topup_requests_page.dart:24`) — تناسق مالي (شحن/شراء)، مع بقاء الباب مفتوحًا لنقله لاحقًا (زر واحد).

## المبدأ (جمع البيانات من API الحالي)
1. `GET /admin/users?limit=100&page=N` — مكرر حتى تغطية `meta.total` ⇐ قائمة `{id, full_name, username}`.
2. لكل مستخدم `GET /admin/users/:id/purchases` — بموازاة **10 طلبات في كل دفعة** مع تقدّم `loaded/total`.
   - حقوله: `id, course_id, course_name, specialization_name, teacher_id, price_paid, teacher_share, created_at` (بلا `source` وبلا اسم المستخدم ⇐ نُضيف `full_name/username` من الخطوة 1).
   - فشل مستخدم واحد ⇐ يتخطّى (تسامح جزئي).
3. دمج + ترتيب تنازلي بـ`created_at` (مقارنة نص ISO آمنة).
4. حجم محفوظ: القاعدة الحالية 9 مستخدمين/11 عملية ⇐ ثوانٍ؛ مع مؤشر `n/m` لأي نمو.

## الملفات
### جديد
1. `mobile/lib/modules/admin/purchases/purchases_controller.dart`
   - `PurchasesAdminController extends GetxController` (نمط `users_controller.dart`):
     - `isLoading/loadedUsers/totalUsers/items/typeFilter/searchQuery` + `searchCtrl` مع debounce 450ms (بحث محلي بلا إعادة تحميل).
     - `load()`: جمع المستخدمين (صفحات limit=100، سقف 100 صفحة) ثم `Future.wait` على دفعات 10 ← `userPurchases(id)` ← إثراء الصفوف ← `sort` تنازلي.
     - `filteredItems`: فلترة بالنص (اسم/username/كورس/تخصص) + النوع (`PURCHASED/FREE`).
     - `isFree(p)`: `double.tryParse(price_paid) == 0` (مبرَّر: `grantCourseToUser:1053` يحفظ `pricePaid='0.00'` دائماً).
2. `mobile/lib/modules/admin/purchases/purchases_page.dart`
   - `PurchasesPage` + `GetBuilder(init: PurchasesAdminController())` (نمط صفحات الأدمن).
   - `GradientAppBar(title: 'عمليات الشراء')` (زر رجوع تلقائي).
   - حقل بحث `CustomTextField` + 3 شرائح: الكل/شراء/مجاني (نمط `_filterChip` من `users_page`).
   - أثناء التحميل: `LinearProgressIndicator(value: loaded/total)` + نص `جارٍ جلب المشتريات… n/m`؛ و`LoadingListShimmer` عند الفراغ.
   - حالة فارغة `EmptyState(receipt_long_outlined)`: «لا توجد عمليات» + سطر الويب «لم يتم تسجيل أي شراء أو منحة مجانية بعد.» (أو «جرّب تعديل البحث أو الفلتر» إن كان فلتر/بحث نشطاً).
   - بطاقة صف: أيقونة دائرية (.primary للشراء/.success للمجاني) + الاسم **+ شارة النوع** + `@username • الكورس` + `التخصص • التاريخ (formatArabicDate)` + `formatAmount(price_paid) SYP`.

### تعديل
3. `mobile/lib/app/routes/app_routes.dart`: `static const String adminPurchases = '/admin/purchases';`
4. `mobile/lib/app/routes/app_pages.dart`: استيراد الصفحتين + 
   ```dart
   GetPage(name: AppRoutes.adminPurchases, page: () => const PurchasesPage(), binding: BindingsBuilder(() {
     Get.lazyPut(() => PurchasesAdminController());
   })),
   ```
   (بلا customTransition — كما `adminUserDetail`).
5. `mobile/lib/modules/admin/topups/topup_requests_page.dart:24`:
   ```dart
   appBar: GradientAppBar(
     title: 'طلبات الشحن',
     actions: [
       IconButton(
         icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
         tooltip: 'عمليات الشراء',
         onPressed: () => Get.toNamed(AppRoutes.adminPurchases),
       ),
     ],
   ),
   ```
   (إزالة `const` من GradientAppBar + استيراد `app_routes.dart`).
6. `mobile/android/app/build.gradle.kts`: `versionCode = 35` / `versionName = "1.0.34"`.

### بلا تعديل
- `admin_provider.dart` (الدالتان `users()`/`userPurchases(id)` موجودتان ✓)، الباك، القاعدة.

## حدود معلنة
- نوع العملية **مستنتج** من السعر (API لا يُرجع `source`) ⇐ دورة مجانية تظهر «مجاني» لا «شراء».
- بحث محلي بعد التحميل الكلي؛ لا فرز/ترقيم صفحات على الخادم.

## التسليم
1. `flutter analyze` (خط الأساس **22**).
2. bump → `flutter build apk --release` → توقيع فوري `apksigner` (SIGNED_OK + DN `CN=Student Center`).
3. `adb install -r` على هواوي ⇐ تحقق `35/1.0.34` ⇐ إطلاق ⇐ تقرير.
