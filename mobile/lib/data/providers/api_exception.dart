import 'package:dio/dio.dart';

String apiErrorMessage(Object error, {String fallback = 'حدث خطأ، حاول مرة أخرى'}) {
  if (error is! DioException) return fallback;

  final status = error.response?.statusCode;
  final data = error.response?.data;
  String? serverMsg;
  if (data is Map && data['message'] is String) {
    serverMsg = (data['message'] as String).trim();
  }

  if (serverMsg != null && serverMsg.isNotEmpty) {
    final m = serverMsg.toLowerCase();
    if (m.contains('insufficient')) return 'الرصيد غير كافٍ';
    if (m.contains('already') && m.contains('submit')) return 'هذا الطلب مُرسل بالفعل';
    if (m.contains('already')) return 'لقد قمت بهذه العملية سابقاً';
    if (m.contains('linked to another device')) return 'الحساب مرتبط بجهاز آخر';
    if (m.contains('invalid') || m.contains('credential') || m.contains('password')) {
      if (status == 401) return 'اسم المستخدم أو كلمة المرور غير صحيحة';
      if (m.contains('password')) return 'كلمة المرور الحالية غير صحيحة';
    }
    if (m.contains('pending')) return 'لديك طلبات شحن معلقة بالفعل';
    return serverMsg;
  }

  switch (status) {
    case 400:
      return 'بيانات غير صالحة';
    case 401:
      return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    case 403:
      return 'غير مسموح بهذا الإجراء';
    case 404:
      return 'العنصر المطلوب غير موجود';
    case 409:
      return 'تعذر إتمام العملية، قد تكون مكررة';
    case 422:
      return 'البيانات المدخلة غير صحيحة';
    case 429:
      return 'محاولات كثيرة جداً، حاول لاحقاً';
    default:
      break;
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown) {
    return 'تعذر الاتصال بالخادم، تحقق من الشبكة';
  }

  if (status != null && status >= 500) {
    return 'خطأ في الخادم، حاول لاحقاً';
  }

  return fallback;
}
