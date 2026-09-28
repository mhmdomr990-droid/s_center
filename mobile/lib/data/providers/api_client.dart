import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class ApiClient {
  // لا عنوان افتراضي مطبوع — المستخدم يُدخل العنوان في شاشة الدخول
  static const String defaultBaseUrl = '';

  // العنوان الفعلي القابل للتغيير وقت التشغيل — مصدره حقل شاشة الدخول
  static String baseUrl = defaultBaseUrl;

  // مفتاح حفظ العنوان الذي أدخله المستخدم في SharedPreferences
  static const String overrideKey = 'api_base_url_v1';

  static const Duration timeout = Duration(seconds: 30);

  late final Dio _dio;
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // تطبيق عنوان جديد فوراً (الطلبات + روابط الوسائط
  // لأن MediaProvider.origin يقرأ ApiClient.baseUrl ديناميكياً)
  void applyBaseUrl(String value) {
    baseUrl = value;
    _dio.options.baseUrl = value;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    void Function(int, int)? onSendProgress,
    Options? options,
  }) {
    return _dio.post(
      path,
      data: data,
      options: options ?? (headers != null ? Options(headers: headers) : null),
      onSendProgress: onSendProgress,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    void Function(int, int)? onSendProgress,
    Options? options,
  }) {
    return _dio.patch(
      path,
      data: data,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
