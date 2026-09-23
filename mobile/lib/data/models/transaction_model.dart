class TransactionModel {
  final int id;
  final String type;
  final String amount;
  final String balanceAfter;
  final String? description;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      amount: (json['amount'] ?? '0.00').toString(),
      balanceAfter: (json['balance_after'] ?? '0.00').toString(),
      description: _trDescription(json['description']),
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  static String? _trDescription(String? description) {
    if (description == null || description.isEmpty) return description;
    if (description.startsWith('Purchased course: ')) {
      return 'شراء دورة: ${description.substring('Purchased course: '.length)}';
    }
    if (description.startsWith('Top-up request approved: ')) {
      return 'تمت الموافقة على شحن الرصيد: ${description.substring('Top-up request approved: '.length)}';
    }
    if (description.startsWith('Top-up request rejected')) {
      return 'تم رفض طلب الشحن';
    }
    return description;
  }

  bool get isTopup => type == 'TOPUP';
  bool get isPurchase => type == 'PURCHASE';
}
