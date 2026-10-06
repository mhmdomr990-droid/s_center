# تخصص + هاتف في التسجيل و«حسابي» — تطبيق Flutter فقط — 1.0.31 (Waydroid)

## القرارات (بتأكيد المستخدم)
1. **لا تعديلات على الباك إند** إطلاقاً (حُذفت ميزة تغيير الهاتف في «حسابي» — الهاتف يُعرض قراءة فقط).
2. اختيار التخصص **إلزامي** في التسجيل (مطابق للويب).
3. فلتر الكورسات: افتراضياً تخصص الطالب + تصفح مفتوح لأي تخصص (سلوك الباك الجديد — بلا تعديل في التطبيق).

## مقدمة: الباك إند جاهز للاستقبال (commits `421d0c5`+`5e80088`)
- `POST /auth/register` يقبل `phone` + `specialization_id` (`.strict()` ⇐ **يرفض** حقولاً غير معرّفة ⇒ **النشر إلزامي**).
- `GET /specializations` بلا مصادقة (يُستخدم قبل الدخول).
- `me/login/register` تعيد `specialization_id` + `phone`.
- الكورسات بلا `specializationId` ⇐ تُصفّي حسب تخصص الطالب تلقائياً.
- ⚠️ **شرط التسليم**: نشر هذه الـcommits على الخادم `143.244.151.183` (بإشراف المطوّر) + وجود أعمدة `users.phone` / `users.specialization_id` في قاعدة بياناته (`DB_SYNC=true` محلياً ⇐ تلقائي؛ السيرفر需 تأكيد).

## التعديلات (mobile/ فقط)

### 1) `data/models/user_model.dart`
إضافة حقول: `phone` (String?) + `specializationId` (int?) + `specializationName` (String?) مع قراءتها من JSON (`phone`, `specialization_id`, `specialization_name`) — name قد تكون null (الباك لا يعيدها) ⇒ نكمل من مسار التخصصات (بند 4).

### 2) `data/providers/auth_provider.dart`
- `register(...)`: إضافة `phone` (String?) + `specializationId` (int) — ترسل `phone` فقط إن非-farغة، و`specialization_id` دائماً.

### 3) `modules/auth/auth_controller.dart`
- حقول جديدة: `registerPhoneCtrl` (TextEditingController + dispose) + `registerSpecializationId` (Rx<int?>) + `specializations` (RxList<SpecializationModel>) + `isLoadingSpecializations`/`specializationsError` (Rx).
- `loadSpecializations()`: عبر `CatalogProvider` (المسار `/specializations` العام) — تُستدعى من `onInit` (مرة واحدة، fire-and-forget) + إعادة محاولة عند الفشل.
- `register()`: تحققات جديدة:
  - التخصص مطلوب ⇐ «يرجى اختيار الاختصاص».
  - الهاتف اختياري: إن وُجد ⇐ تحقق `^\+?[0-9\s\-()]{7,30}$` (نفس شرط الباك) ⇐ وإلا رسالة «رقم الهاتف غير صالح».
  - إرسال الحقول الجديدة.
- (ملحوظة: تحققات الاسم/الكلمة المرور الحالية تبقى كما هي مع رسالة الباك العربية بعد النشر.)

### 4) `modules/auth/register_page.dart`
- **Dropdown «الاختصاص»** (`DropdownButtonFormField<int>`, decoration مطابق لتنسيق `CustomTextField`, `Items: «اختر الاختصاص»` + القائمة; حالة تحميل = spinner; حالة خطأ = نص + إعادة محاولة) — يوضع بعد «الاسم الكامل».
- **حقل «رقم الهاتف (اختياري)»** (`CustomTextField`, `keyboardType.phone`) — بعد التأكيد أو قبله.
- تعطيل زر التسجيل عند فشل تحميل التخصصات (إلزام ⇐ لا تسجيل بلا قائمة).

### 5) `modules/student/profile/profile_controller.dart` + `profile_page.dart`
- في بطاقة «حسابي» العلوية (تحت الاسم): سطر الهاتف `phone` إن وُجد + سطر التخصص — الاسم عبر جلب قائمة التخصصات العامة (`CatalogProvider.getSpecializations` صامتاً + دعم `OfflineCache` إن وُجد) وإلا نعرض فقط إن وُجد الاسم.
- **بلا زر تعديل** (قرار المستخدم) — الهاتف قراءة فقط.

### 6) الكورسات — **بلا تعديل**
- `home_controller.getCourses()` بدون معاملات ✓ و`courses_controller` عند `selectedSpecializationId == null` ✓ ⇐ الباك يعيد كورسات تخصص الطالب بعد النشر؛ الفلتر يسمح بالتصفح المفتوح ✓.

## التسليم
1. `versionCode = 32`، `versionName = "1.0.31"`.
2. `flutter analyze` ⇐ خط الأساس **22 info**.
3. `flutter build apk --release` ⇐ توقيع يدوي بعد البناء (`scenter-release.jks`) ⇐ شعبة `c9828eac`.
4. Waydroid: إن متوقف ⇐ `nohup waydroid session start` + `boot_completed=1` ⇐ سحب stdin ⇐ `pm install -r` ⇐ `Success` ⇐ تحقق `32/1.0.31` ⇐ إطلاق.

## التحقق (على الخادم المنشور)
1. تسجيل: dropdown تخصص (إلزام) + هاتف اختياري ⇐ نجاح ⇐ الدخول لـStudentShell.
2. «حسابي»: يعرض الهاتف (إن أُدخل) + اسم التخصص.
3. الكورسات: تظهر كورسات تخصص الطالب افتراضياً + الفلتر يتيح تصفح تخصصات أخرى.
4. هاتف غير صالح ⇐ رسالة قبل الإرسال؛ فشل تحميل التخصصات ⇐ زر التسجيل معطّل + رسالة.
5. PDF/المسارات القديمة ومسارات الأدمن/المعلم غير متأثرة.
