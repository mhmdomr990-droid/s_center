import 'package:dio/dio.dart';
import 'api_client.dart';

class MediaProvider {
  final ApiClient _api;

  MediaProvider(this._api);

  static String get origin {
    final base = ApiClient.baseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static String absolute(String path) {
    if (path.startsWith('http')) return path;
    return origin + (path.startsWith('/') ? path : '/$path');
  }

  Future<Response> getStreamUrl(int lectureId) {
    return _api.post('/lectures/$lectureId/stream-url');
  }

  Future<Response> getDownloadUrl(int lectureId) {
    return _api.post('/lectures/$lectureId/download-url');
  }
}
