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
      description: json['description'],
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  bool get isTopup => type == 'TOPUP';
  bool get isPurchase => type == 'PURCHASE';
}
