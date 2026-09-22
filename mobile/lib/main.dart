import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'app/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'data/providers/api_client.dart';
import 'data/services/storage_service.dart';
import 'data/services/device_service.dart';
import 'modules/auth/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF2E7D32),
    statusBarIconBrightness: Brightness.light,
  ));

  final storageService = StorageService();
  final deviceService = DeviceService();
  final apiClient = ApiClient(storageService);

  Get.put(storageService);
  Get.put(deviceService);
  Get.put(apiClient);
  Get.put(AuthController());

  runApp(const SCenterApp());
}

class SCenterApp extends StatelessWidget {
  const SCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Student Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: AppRoutes.login,
      getPages: AppPages.pages,
    );
  }
}
