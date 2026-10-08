import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String apiErrorMessage(Object error, {String fallback = 'حدث خطأ، حاول مرة أخرى'}) {
  if (error is! DioException) return fallback;

  final status = error.response?.statusCode;
  final data = error.response?.data;
  String? serverMsg;
  if (data is Map && data['message'] is String) {
    serverMsg = (data['message'] as String).trim();
  }

  // نص خادم طويل (أكثر من 120 حرفاً) لا يصل للمستخدم — نتجاهله
  // ونعتمد الرسالة المختصرة حسب الحالة أدناه
  if (serverMsg != null && serverMsg.length > 120) serverMsg = null;

  // رفض لحجم الملف/الطلب — رسالة واضحة مهما جاء نص الخادم (أو HTML من الشبكة)
  if (status == 413) return 'حجم الملف يتجاوز الحد المسموح على الخادم';

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
    // المستخدم يرى سطراً واحداً فقط — والتفاصيل (العنوان/السبب/النوع/
    // الفحص) تبقى حصراً في نسخ التطوير للتشخيص
    if (kDebugMode) {
      final origin = error.requestOptions.uri.origin;
      final where = origin.isEmpty ? '' : '\nالعنوان: $origin';
      var cause = error.error?.toString() ?? '';
      if (cause.length > 160) cause = cause.substring(0, 160);
      final why = cause.isEmpty ? '' : '\nالسبب: $cause';
      final hint = _netHint(cause);
      final hintLine = hint.isEmpty ? '' : '\n$hint';
      debugPrint(
          'انقطاع شبكة:$where$why\nالنوع: ${error.type.name}$hintLine');
    }
    return 'فشل الاتصال بالخادم';
  }

  if (status != null && status >= 500) {
    return 'خطأ في الخادم، حاول لاحقاً';
  }

  return fallback;
}

// تفسير عربي مباشر لسبب فشل الشبكة من نظام التشغيل
String _netHint(String cause) {
  final errno = RegExp(r'errno = (\d+)').firstMatch(cause)?.group(1);
  switch (errno) {
    case '13':
      return 'الفحص: التطبيق لا يملك إذن الوصول للإنترنت — ثبّت APK جديدة';
    case '1':
      return 'الفحص: النظام منع الوصول (EPERM)';
    case '101':
      return 'الفحص: الجهاز خارج الشبكة (ENETUNREACH)';
    case '113':
      return 'الفحص: لا يمكن الوصول لعنوان الخادم (EHOSTUNREACH)';
    case '111':
      return 'الفحص: منفذ الخادم مغلق أو عنوان خاطئ (Connection refused)';
    case '110':
      return 'الفحص: انتهت المهلة — حجب أو شبكة غير متصلة (timeout)';
    case '104':
      return 'الفحص: انقطع الاتصال أثناء الاستجابة (ECONNRESET)';
    case '102':
      return 'الفحص: الاتصال أُلغي من الشبكة (ECONNABORTED)';
  }
  if (cause.contains('Connection refused')) {
    return 'الفحص: منفذ الخادم مغلق أو عنوان خاطئ (Connection refused)';
  }
  if (cause.contains('Failed host lookup') || cause.contains('Name or service')) {
    return 'الفحص: فشل تحويل العنوان (DNS) — تأكد من كتابة IP بأرقام إنجليزية';
  }
  if (cause.contains('timeout') || cause.contains('Timeout')) {
    return 'الفحص: انتهت المهلة — ربما حجب من الجهاز أو الشبكة';
  }
  if (cause.contains('Cleartext')) {
    return 'الفحص: النظام يمنع HTTP غير المشفر — ثبّت APK هذه';
  }
  return '';
}
