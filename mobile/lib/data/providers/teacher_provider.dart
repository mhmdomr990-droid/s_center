import 'package:dio/dio.dart';
import 'api_client.dart';

class TeacherProvider {
  final ApiClient _api;

  TeacherProvider(this._api);

  Future<Response> getCourses() {
    return _api.get('/teacher/courses');
  }

  Future<Response> getDashboard({int days = 30}) {
    return _api.get('/teacher/dashboard', queryParameters: {'days': days});
  }

  Future<Response> getCourseById(int id) {
    return _api.get('/teacher/courses/$id');
  }

  Future<Response> updateCourseDescription(int id, String description) {
    return _api.patch('/teacher/courses/$id', data: {'description': description});
  }

  Future<Response> getCourseLectures(int courseId) {
    return _api.get('/teacher/courses/$courseId/lectures');
  }

  Future<Response> createLecture(int courseId, {required String title, required String type, String? url, String? content, int? sortOrder}) {
    return _api.post('/teacher/courses/$courseId/lectures', data: {
      'title': title,
      'type': type,
      if (url != null) 'url': url,
      if (content != null) 'content': content,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  Future<Response> updateLecture(int id, {String? title, String? type, String? url, String? content, int? sortOrder}) {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (type != null) data['type'] = type;
    if (url != null) data['url'] = url;
    if (content != null) data['content'] = content;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    return _api.patch('/teacher/lectures/$id', data: data);
  }

  Future<Response> deleteLecture(int id) {
    return _api.delete('/teacher/lectures/$id');
  }

  Future<Response> toggleLecturePublished(int id, bool isPublished) {
    return _api.patch('/teacher/lectures/$id/published', data: {'is_published': isPublished});
  }

  Future<Response> reorderLectures(int courseId, List<int> lectureIds) {
    return _api.put('/teacher/courses/$courseId/lectures/order', data: {
      'lecture_ids': lectureIds,
    });
  }

  Future<Response> getStats({String? from, String? to}) {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    return _api.get('/teacher/stats', queryParameters: params);
  }

  Future<Response> getEarnings({String? month}) {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    return _api.get('/teacher/earnings', queryParameters: params);
  }

  Future<Response> getPayouts() {
    return _api.get('/teacher/payouts');
  }
}
