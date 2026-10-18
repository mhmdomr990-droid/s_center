import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../providers/api_client.dart';

/// حالة السيرفر القادمة من `GET /api/app-status`
class AppStatus {
  final bool maintenance;
  final String message;
  const AppStatus({required this.maintenance, required this.message});
}

class AppStatusService {
  /// فحص سريع عند فتح/عودة التطبيق — مهلة قصيرة (8 ثوانٍ) للاستجابة.
  /// تعيد `null` عند فشل الشبكة أو شكل غير متوقع (لا نافذة — التطبيق يكمل).
  static Future<AppStatus?> fetch() async {
    try {
      final api = Get.find<ApiClient>();
      final response = await api.dio.get(
        '/app-status',
        options: Options(receiveTimeout: const Duration(seconds: 8)),
      );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is! Map) return null;
      return AppStatus(
        maintenance: data['maintenance'] == true,
        message: '${data['message'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }
}
