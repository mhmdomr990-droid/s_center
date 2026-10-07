import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class PurchaseProvider {
  final ApiClient _api;

  PurchaseProvider(this._api);

  Future<Response> purchaseCourse(int courseId) {
    return _api.post(
      '/courses/$courseId/purchase',
      headers: {'Idempotency-Key': const Uuid().v4()},
    );
  }

  Future<Response> getMyCourses() {
    return _api.get('/me/courses');
  }

  Future<Response> getMyPayments() {
    return _api.get('/me/payments');
  }

  // ---- طلبات تبديل المواد ----
  Future<Response> requestSwap({
    required int oldPurchaseId,
    required int newCourseId,
    String? reason,
  }) {
    return _api.post('/course-swap-requests', data: {
      'old_purchase_id': oldPurchaseId,
      'new_course_id': newCourseId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

}
