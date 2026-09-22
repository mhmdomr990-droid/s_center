class PayoutModel {
  final int id;
  final int teacherId;
  final String amount;
  final String? note;
  final int createdBy;
  final DateTime? createdAt;

  PayoutModel({
    required this.id,
    required this.teacherId,
    required this.amount,
    this.note,
    required this.createdBy,
    this.createdAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      amount: (json['amount'] ?? '0.00').toString(),
      note: json['note'],
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
