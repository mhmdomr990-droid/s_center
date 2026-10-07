import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'api_client.dart';

// جميع مسارات /api/admin/* — محمية بـ requireRole(ADMIN) في الباك إند
class AdminProvider {
  final ApiClient _api;

  AdminProvider(this._api);

  // شارات (عدد طلبات الشحن المعلّقة)
  Future<Response> badges() => _api.get('/admin/badges');

  // ---- طلبات الشحن ----
  Future<Response> topupRequests({String status = 'PENDING', int page = 1, int limit = 20}) {
    return _api.get('/admin/topup-requests', queryParameters: {
      'status': status,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> approveTopup(int id) => _api.post('/admin/topup-requests/$id/approve');

  Future<Response> rejectTopup(int id, {required String reason}) {
    return _api.post('/admin/topup-requests/$id/reject', data: {'reason': reason});
  }

  // ---- المستخدمون ----
  Future<Response> users({String? search, String? role, int page = 1, int limit = 20}) {
    return _api.get('/admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> userById(int id) => _api.get('/admin/users/$id');

  Future<Response> userTransactions(int id) => _api.get('/admin/users/$id/transactions');

  Future<Response> userPurchases(int id) => _api.get('/admin/users/$id/purchases');

  Future<Response> grantCourse(int userId, int courseId) =>
      _api.post('/admin/users/$userId/grant-course', data: {'course_id': courseId});

  Future<Response> revokeCourseGrant(int userId, int courseId) =>
      _api.delete('/admin/users/$userId/grant-course', data: {'course_id': courseId});

  Future<Response> setUserActive(int id, {required bool isActive}) {
    return _api.patch('/admin/users/$id/active', data: {'is_active': isActive});
  }

  // ---- طلبات تبديل المواد ----
  Future<Response> courseSwapRequests() => _api.get('/admin/course-swap-requests');

  Future<Response> approveCourseSwap(int id, {String? note}) {
    return _api.post('/admin/course-swap-requests/$id/approve', data: {
      if (note != null && note.isNotEmpty) 'admin_note': note,
    });
  }

  Future<Response> rejectCourseSwap(int id, {required String reason}) {
    return _api.post('/admin/course-swap-requests/$id/reject', data: {
      'reason': reason,
    });
  }

  Future<Response> resetUserDevice(int id) => _api.post('/admin/users/$id/reset-device');

  Future<Response> adjustBalance(int id, {required String amount, required String description}) {
    return _api.post('/admin/users/$id/adjust-balance', data: {
      'amount': amount,
      'description': description,
    });
  }

  Future<Response> resetPassword(int id, {required String newPassword}) {
    return _api.post('/admin/users/$id/reset-password', data: {'new_password': newPassword});
  }

  // إضافة طالب — عبر مسار اللوحة /panel/admin/students الموجود في الباك
  // (كوكي panel_token = توكن الجلسة نفسه + CSRF عبر الترويسة)
  // الباك يرد بـ302 + كوكي panel_flash بنجاح/خطأ ⇒ نقرؤه بدلاً من JSON
  Future<String?> createStudent({
    required String username,
    required String fullName,
    required String password,
    String? phone,
    required int specializationId,
  }) async {
    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      return 'انتهت الجلسة، أعد تسجيل الدخول';
    }

    final csrf = _randomHex(48);
    final body = <String, dynamic>{
      'username': username,
      'full_name': fullName,
      'password': password,
      'specialization_id': specializationId,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;

    final response = await _api.post(
      '/panel/admin/students',
      data: body,
      options: Options(
        headers: {
          'Origin': Uri.parse(ApiClient.baseUrl).origin,
          'Cookie': 'panel_token=$token; panel_csrf_token=$csrf',
          'x-csrf-token': csrf,
        },
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode != 302) {
      return 'تعذر إنشاء الطالب، حاول مرة أخرى';
    }

    final flash = _panelFlash(response);
    if (flash == null || flash.$1 != 'success') {
      final message = flash?.$2 ?? 'تعذر إنشاء الطالب، حاول مرة أخرى';
      if (message == 'Username already exists') return 'اسم المستخدم موجود مسبقاً';
      return message;
    }
    return null;
  }

  static String _randomHex(int length) {
    const chars = '0123456789abcdef';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static (String, String)? _panelFlash(Response response) {
    final headers = response.headers.map['set-cookie'];
    if (headers == null) return null;
    for (final header in headers) {
      final match = RegExp('panel_flash=([^;]+)').firstMatch(header);
      if (match == null) continue;
      try {
        final decoded =
            utf8.decode(base64.decode(Uri.decodeComponent(match.group(1)!)));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        final type = json['type']?.toString();
        if (type == null) continue;
        return (type, json['message']?.toString() ?? '');
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // ---- التخصصات ----
  Future<Response> specializations({String? search, int page = 1, int limit = 100}) {
    return _api.get('/admin/specializations', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> createSpecialization({required String name}) {
    return _api.post('/admin/specializations', data: {'name': name});
  }

  Future<Response> updateSpecialization(int id, {required String name}) {
    return _api.patch('/admin/specializations/$id', data: {'name': name});
  }

  Future<Response> setSpecializationPublished(int id, {required bool isPublished}) {
    return _api.patch('/admin/specializations/$id/published', data: {'is_published': isPublished});
  }

  Future<Response> deleteSpecialization(int id) => _api.delete('/admin/specializations/$id');

  // ---- الكورسات ----
  Future<Response> courses({int? specializationId, int? year, String? search, int page = 1, int limit = 20}) {
    return _api.get('/admin/courses', queryParameters: {
      if (specializationId != null) 'specializationId': specializationId,
      if (year != null) 'year': year,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> createCourse(Map<String, dynamic> body) => _api.post('/admin/courses', data: body);

  Future<Response> updateCourse(int id, Map<String, dynamic> body) {
    return _api.patch('/admin/courses/$id', data: body);
  }

  Future<Response> setCoursePublished(int id, {required bool isPublished}) {
    return _api.patch('/admin/courses/$id/published', data: {'is_published': isPublished});
  }

  Future<Response> deleteCourse(int id) => _api.delete('/admin/courses/$id');

  // ---- المحاضرات ----
  Future<Response> lectures({int? courseId, int page = 1, int limit = 50}) {
    return _api.get('/admin/lectures', queryParameters: {
      if (courseId != null) 'course_id': courseId,
      'page': page,
      'limit': limit,
    });
  }

  static final _uploadOptions =
      Options(receiveTimeout: const Duration(minutes: 30));

  static String _fileName(String path) =>
      path.split(RegExp(r'[/\\]')).last;

  static DioMediaType _fileContentType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'webm':
        return DioMediaType('video', 'webm');
      case 'mov':
        return DioMediaType('video', 'quicktime');
      case 'mkv':
        return DioMediaType('video', 'x-matroska');
      case 'pdf':
        return DioMediaType('application', 'pdf');
      default:
        return DioMediaType('video', 'mp4');
    }
  }

  // حقل `video` يحمل الفيديو أو ملف PDF — مطابق لـlectureVideoUpload.single('video')
  static MultipartFile _uploadFile(String? path,
          {Uint8List? bytes, String? name}) =>
      bytes != null && name != null
          ? MultipartFile.fromBytes(
              bytes,
              filename: name,
              contentType: _fileContentType(name),
            )
          : MultipartFile.fromFileSync(
              path!,
              filename: _fileName(path),
              contentType: _fileContentType(path),
            );

  Future<Response> createLecture({
    required int courseId,
    required String title,
    required String type,
    String? url,
    String? content,
    int? sortOrder,
    String? videoFilePath,
    Uint8List? fileBytes,
    String? fileName,
    void Function(int, int)? onSendProgress,
  }) async {
    if (videoFilePath != null) {
      final form = FormData.fromMap({
        'course_id': courseId.toString(),
        'title': title,
        'type': type,
        if (url != null) 'url': url,
        if (content != null) 'content': content,
        if (sortOrder != null) 'sort_order': sortOrder.toString(),
        'video': _uploadFile(videoFilePath, bytes: fileBytes, name: fileName),
      });
      return _api.post(
        '/admin/lectures',
        data: form,
        onSendProgress: onSendProgress,
        options: _uploadOptions,
      );
    }
    return _api.post('/admin/lectures', data: {
      'course_id': courseId,
      'title': title,
      'type': type,
      if (url != null) 'url': url,
      if (content != null) 'content': content,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  Future<Response> updateLecture(
    int id, {
    String? title,
    String? type,
    String? url,
    String? content,
    int? sortOrder,
    String? videoFilePath,
    Uint8List? fileBytes,
    String? fileName,
    void Function(int, int)? onSendProgress,
  }) async {
    if (videoFilePath != null) {
      final form = FormData.fromMap({
        if (title != null) 'title': title,
        if (type != null) 'type': type,
        if (url != null) 'url': url,
        if (content != null) 'content': content,
        if (sortOrder != null) 'sort_order': sortOrder.toString(),
        'video': _uploadFile(videoFilePath, bytes: fileBytes, name: fileName),
      });
      return _api.patch(
        '/admin/lectures/$id',
        data: form,
        onSendProgress: onSendProgress,
        options: _uploadOptions,
      );
    }
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (type != null) data['type'] = type;
    if (url != null) data['url'] = url;
    if (content != null) data['content'] = content;
    if (sortOrder != null) data['sort_order'] = sortOrder;
    return _api.patch('/admin/lectures/$id', data: data);
  }

  Future<Response> setLecturePublished(int id, {required bool isPublished}) {
    return _api.patch('/admin/lectures/$id/published', data: {'is_published': isPublished});
  }

  Future<Response> deleteLecture(int id) => _api.delete('/admin/lectures/$id');

  // ---- المدرسون ----
  Future<Response> teachers() => _api.get('/admin/teachers');

  Future<Response> teacherById(int id) => _api.get('/admin/teachers/$id');

  Future<Response> createTeacher({
    required String username,
    required String fullName,
    required String password,
  }) {
    return _api.post('/admin/teachers', data: {
      'username': username,
      'full_name': fullName,
      'password': password,
    });
  }

  Future<Response> teacherPayouts(int id) => _api.get('/admin/teachers/$id/payouts');

  Future<Response> createTeacherPayout(int id, {required String amount, String? note}) {
    return _api.post('/admin/teachers/$id/payouts', data: {
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  // ---- الإشعارات ----
  Future<Response> sendNotificationToAll({required String title, required String body}) {
    return _api.post('/admin/notifications', data: {'all': true, 'title': title, 'body': body});
  }

  Future<Response> sendNotificationToUser({
    required int userId,
    required String title,
    required String body,
  }) {
    return _api.post('/admin/notifications', data: {
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }
}
