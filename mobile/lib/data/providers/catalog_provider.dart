import 'package:dio/dio.dart';
import 'api_client.dart';

class CatalogProvider {
  final ApiClient _api;

  CatalogProvider(this._api);

  Future<Response> getSpecializations() {
    return _api.get('/specializations');
  }

  Future<Response> getCourses({int? specializationId, int? year}) {
    final params = <String, dynamic>{};
    if (specializationId != null) params['specializationId'] = specializationId;
    if (year != null) params['year'] = year;
    return _api.get('/courses', queryParameters: params);
  }

  Future<Response> getCourseLectures(int courseId) {
    return _api.get('/courses/$courseId/lectures');
  }
}
