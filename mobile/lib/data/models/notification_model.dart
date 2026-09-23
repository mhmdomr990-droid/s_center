class NotificationModel {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  static String _trTitle(String title) {
    switch (title) {
      case 'Purchase successful':
        return 'تم شراء الدورة بنجاح';
      case 'Top-up approved':
        return 'تمت الموافقة على شحن الرصيد';
      case 'Top-up rejected':
        return 'تم رفض طلب الشحن';
      default:
        return title;
    }
  }

  static String _trBody(String body) {
    if (body.startsWith('You purchased ')) {
      return 'لقد اشتريت ${body.substring('You purchased '.length)}';
    }
    if (body.startsWith('Your balance was topped up by ')) {
      return 'تم شحن رصيدك بمبلغ ${body.substring('Your balance was topped up by '.length)}';
    }
    if (body.startsWith('Your top-up request was rejected: ')) {
      return 'تم رفض طلب شحنك: ${body.substring('Your top-up request was rejected: '.length)}';
    }
    return body;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: _trTitle(json['title'] ?? ''),
      body: _trBody(json['body'] ?? ''),
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
