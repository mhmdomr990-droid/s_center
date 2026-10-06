# خطة: إضافة طالب من تبويب «المستخدمون» في تطبيق الأدمن

## الحالة الفعلية (تحقّقت منها الآن)
- **تطبيق Flutter**: تبويب المستخدمون (`mobile/lib/modules/admin/users/`) **بلا زر إضافة** إطلاقاً.
- **الويب (اللوحة)**: لديه «إضافة طالب» كاملاً (`POST /panel/admin/students`) — لا نمسّه.
- **الخادم البعيد**: `POST /api/admin/users` ⇐ **404 مؤكد** (اختبار بتوكن أدمن asmaa، `Cannot POST /api/admin/users`). ⇒ المسار مفقود في كل المستودعات (origin/main, upstream/main, Flutter-App) وفي الخادم.
- **جاهز في الباك**: `createStudent()` في `src/modules/admin/service.ts:1181` و `studentCreateSchema` في `src/modules/admin/schemas.ts:202` (بـ phone/specialization_id/device_id) — كلاهما يُستعمل من اللوحة أصلاً.
- **جاهز في التطبيق**: `AdminProvider.specializations()` ⇐ `GET /admin/specializations`؛ نمط «إضافة معلم» كاملاً في `teachers_page.dart` (أيقونة AppBar + `_showCreateDialog`) — نُكرّره.
- **قرار المستخدم**: الاختصاص **إلزامي** في نموذج الإضافة (التطبيق فقط — الباك يبقى اختيارياً حتى لا تنكسر اللوحة).
- ميزة الميزة: `GET /api/specializations` (عام) ⇐ 200 ✓ — أي تعديلات التسجيل السابقة مُشرَّنة بالفعل.

## التعديلات

### 1) باك إند (ملفان فقط، ~7 أسطر — يعيد استخدام الموجود دون تغييره)
- `src/modules/admin/controller.ts`:
  - إضافة `createStudent` لقائمة استيراد service.
  - `postAdminCreateStudent` = نسخة حرفية من `postAdminTeacher`: `await createStudent(req.body)` ⇐ `res.status(201).json({ success: true, data })`.
- `src/modules/admin/routes.ts`:
  - استيراد `postAdminCreateStudent` + `studentCreateSchema`.
  - `adminRoutes.post('/users', validate({ body: studentCreateSchema }), postAdminCreateStudent);` (قبل مسارات `users/:id`).
- **لا** تعديل الويب ولا `createStudent` ولا السكيما ⇒ اللوحة لا تتأثر.

### 2) Flutter — `admin_provider.dart`
```dart
Future<Response> createStudent({
  required String username, required String fullName, required String password,
  String? phone, required int specializationId,
}) {
  final data = <String, dynamic>{
    'username': username, 'full_name': fullName, 'password': password,
    'specialization_id': specializationId,
  };
  if (phone != null && phone.isNotEmpty) data['phone'] = phone;
  return _api.post('/admin/users', data: data);
}
```
(بناء map بعبارات `if` — لتجنّب info `use_null_aware_elements` كما في `auth_provider`.)

### 3) Flutter — `users_controller.dart`
- حقن موجود (`_provider`)؛ إضافة:
  - `final busy = false.obs;` + `final specializations = <SpecializationModel>[].obs;`
  - استيراد `specialization_model`؛ في `onInit`: `unawaited(loadSpecializations())` (صامت عند الفشل).
  - `loadSpecializations()` عبر `_provider.specializations(page: 1, limit: 100)`.
  - `Future<void> createStudent({username, fullName, password, phone, specializationId})`: `busy` ⇐ نجاح snackbar «تم إنشاء حساب الطالب» + `await load()` ⇐ فشل snackbar «اسم مستخدم متفرد؟».

### 4) Flutter — `users_page.dart`
- `GradientAppBar(title: 'المستخدمون', actions: [IconButton(icon: Icons.person_add_alt_1_rounded, tooltip: 'طالب جديد', onPressed: ...)])` — مطابق لصفحة المعلمين.
- `_showCreateStudentDialog(context, ctrl)` — `AlertDialog` بحقول:
  1. الاسم الكامل
  2. اسم المستخدم (يُطبَّع `.toLowerCase()`)
  3. كلمة المرور (obscure، ≥8)
  4. الهاتف (اختياري، `TextInputType.phone`)
  5. **Dropdown «الاختصاص» إلزامي** (`DropdownButtonFormField<int>` بـ `initialValue:` من `ctrl.specializations`؛ خيار null = «اختر الاختصاص»؛ إن لم تكن القائمة محمّلة ⇐ مؤشر تحميل/إعادة محاولة — لا زر إنشاء حتى تنجح)
- تحققات قبل الإرسال: username ≥3، fullName ≥2، password ≥8، **specializationId != null** ⇐ وإلا snackbar خطأ.
- زرّان: إلغاء / إنشاء (نفس أسلحة `_showCreateDialog`).

### 5) الإصدار
- `mobile/android/app/build.gradle.kts`: `versionCode = 33` / `versionName = "1.0.32"`.

## التحقق والتسليم (الحلقة المعتادة)
1. `flutter analyze` ⇐ خط الأساس **22** info (0 error/warning).
2. `flutter build apk --release` ← تو签名 فوري `apksigner` ⇐ `SIGNED_OK` + `CN=Student Center`.
3. Waydroid: session/boot ⇐ stdin push ⇐ `pm install -r` ⇐ `Success` ⇐ تحقق `33/1.0.32` ⇐ إطلاق.
4. **اختبار الباك**: إعادة اختبار `POST /api/admin/users` بجسم فارغ + التوكن ⇐ يجب أن تصير **400/422** بدل 404 (آمن — لا ينشئ شيئاً).
5. **لا commit/push** إلا بأمر صريح؛ إبلاغ المستخدم أن نشر ملفَي الباك (`routes.ts`, `controller.ts`) على الخادم البعيد **لازم** لنجاح الإنشاء من التطبيق.
6. ملاحظة أخلاقية تجريبية: أي «إضافة طالب» اختبارية من التطبيق ستنشئ **حساباً حقيقياً على إنتاج** — التنبيه قبل الاختبار، والحذف/الإيقاف بعده إن طُلب.

## المخاطر
- التوكن المستخدم للاختبار صالح حتى `exp 1791918471` (~7 أيام) — يُستخدم للاختبار فقط.
- `authRateLimit` على `/auth/login`: استُهلك طلبان (دخول + لا غير) — لا مشكلة.
- إن ظهر 409 من الباك (اسم مستخدم مكرر) ⇐ الرسالة الجاهزة تتكفّل.
