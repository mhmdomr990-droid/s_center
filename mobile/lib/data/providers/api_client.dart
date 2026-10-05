import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class ApiClient {
  // عنوان الخادم الثابت — لا يُدخل من الواجهة ولا يتغير
  static const String defaultBaseUrl = 'http://143.244.151.183/api';

  // العنوان الفعلي — يبدأ ثابتاً منذ أول إطار
  static String baseUrl = defaultBaseUrl;

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
