import 'dart:async';

import 'package:dio/dio.dart';
import '../../modules/maintenance/maintenance_dialog.dart';
import '../services/storage_service.dart';

class ApiClient {
  // عنوان الخادم الثابت — لا يُدخل من الواجهة ولا يتغير
  static const String defaultBaseUrl = 'http://143.244.151.183/api';

  // العنوان الفعلي — يبدأ ثابتاً منذ أول إطار
  static String baseUrl = defaultBaseUrl;

  // مهل قصيرة: سيرفر مشغول/مقطوع يفشل خلال ثوانٍ بدل 30 ثانية تجمّد
  // (الرفع والوسائط لهما مهل خاصة بهم ولا يمرّون بهذه القيم افتراضياً)
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  late final Dio _dio;
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
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
        // إشارة الصيانة من الباك أثناء العمل ⇐ النافذة الدائمة
        // (الأدمن لا يرى 503 أصلاً — مساراته مستثناة في الباك)
        final data = error.response?.data;
        if (error.response?.statusCode == 503 &&
            data is Map &&
            data['maintenance'] == true) {
          unawaited(showMaintenanceDialog(
              message: data['message'] is String ? data['message'] : null));
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<String?> getToken() => _storage.getToken();

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    void Function(int, int)? onSendProgress,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      options: options ?? (headers != null ? Options(headers: headers) : null),
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    void Function(int, int)? onSendProgress,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch(
      path,
      data: data,
      options: options,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }
}
