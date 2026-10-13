import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'data/providers/api_client.dart';
import 'data/providers/teacher_provider.dart';
import 'data/services/storage_service.dart';
import 'data/services/device_service.dart';
import 'data/services/download_manager.dart';
import 'data/services/screen_guard.dart';
import 'data/services/upload_manager.dart';
import 'modules/auth/auth_controller.dart';
import 'widgets/app_scroll_behavior.dart';
import 'widgets/upload_overlay.dart';

/// تحميل وتسميع خطوط Cairo الخمسة قبل runApp.
/// المفاتيح تُشتق من `.fontFamily` نفسه الذي ستستخدمه google_fonts
/// لرسم النصوص ⇐ لا تخمين لأسماء العائلات.
Future<void> _preloadCairoFonts() async {
  final files = <FontWeight, String>{
    FontWeight.w400: 'assets/fonts/Cairo-Regular.ttf',
    FontWeight.w500: 'assets/fonts/Cairo-Medium.ttf',
    FontWeight.w600: 'assets/fonts/Cairo-SemiBold.ttf',
    FontWeight.w700: 'assets/fonts/Cairo-Bold.ttf',
    FontWeight.w800: 'assets/fonts/Cairo-ExtraBold.ttf',
  };
  for (final entry in files.entries) {
    try {
      final key = GoogleFonts.cairo(fontWeight: entry.key).fontFamily;
      final data = await rootBundle.load(entry.value);
      final loader = FontLoader(key!);
      loader.addFont(Future.value(data));
      await loader.load();
      debugPrint('FONT_PRELOAD_OK $key');
    } catch (e) {
      debugPrint('FONT_PRELOAD_FAIL ${entry.key}: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // خدمة أمامية: استمرار رفع المحاضرات في الخلفية + إشعار عند الاكتمال
  try {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'lecture_upload',
        channelName: 'رفع المحاضرات',
        channelDescription:
            'استمرار رفع الملفات في الخلفية وإشعار عند الاكتمال',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  } catch (e) {
    debugPrint('FGS_INIT_FAIL $e');
  }

  // خطوط Cairo مضمّنة في assets/fonts/ — لا تنزيل من الشبكة إطلاقاً
  // (يمنع ظهور مربعات □□□ في الـ splash قبل وصول الخط وقت التشغيل)
  GoogleFonts.config.allowRuntimeFetching = false;

  // انتظار تسجيل الخطوط قبل runApp — وإلا تُرسم أول إطارات الـ splash
  // بخط بديل (مربعات □□□) حتى يكتمل التحميل الكسول لـ google_fonts
  await _preloadCairoFonts();

  final storageService = StorageService();
  final deviceService = DeviceService();

  final apiClient = ApiClient(storageService);

  final themeController = ThemeController(storageService);
  await themeController.loadSaved();

  Get.put(storageService);
  Get.put(deviceService);
  Get.put(apiClient);
  Get.put(themeController);
  Get.put(AuthController());
  Get.put(DownloadManager(), permanent: true);
  Get.put(UploadManager(TeacherProvider(apiClient)), permanent: true);

  await ScreenGuard.instance.protect();

  runApp(const SCenterApp());
}

class SCenterApp extends StatelessWidget {
  const SCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obx: يعيد تقييم AppTheme.*Theme (getters تلتقط ثوابت AppColors)
    // عند تبديل الثيم — وإلا بقيت ThemeData المخزّنة وقت الإقلاع
    // بألوان الافتراضي فيظل الحوار وحقول Material فاتحة بالوضع الداكن
    return Obx(() {
      return GetMaterialApp(
        title: 'Student Center',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: Get.find<ThemeController>().themeMode.value,
        scrollBehavior: AppScrollBehavior(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                // شريط تقدم الرفع العائم — يبقى فوق أي صفحة
                const UploadOverlay(),
              ],
            ),
          );
        },
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
      );
    });
  }
}
