import 'package:dio/dio.dart';
import 'api_client.dart';

class NotificationProvider {
  final ApiClient _api;

  NotificationProvider(this._api);

  Future<Response> getNotifications({int limit = 20, int offset = 0}) {
    return _api.get('/notifications/', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
  }

  Future<Response> markAsRead(int id) {
    return _api.patch('/notifications/$id/read');
  }

  Future<Response> markAllAsRead() {
    return _api.patch('/notifications/read-all');
  }
}
