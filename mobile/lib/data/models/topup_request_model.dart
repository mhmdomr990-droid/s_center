class TopupRequestModel {
  final int id;
  final String amount;
  final String method;
  final String referenceNumber;
  final String senderName;
  final String? note;
  final String status;
  final String? rejectReason;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  TopupRequestModel({
    required this.id,
    required this.amount,
    required this.method,
    required this.referenceNumber,
    required this.senderName,
    this.note,
    required this.status,
    this.rejectReason,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
  });

  factory TopupRequestModel.fromJson(Map<String, dynamic> json) {
    return TopupRequestModel(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? '0.00').toString(),
      method: json['method'] ?? '',
      referenceNumber: json['reference_number'] ?? '',
      senderName: json['sender_name'] ?? '',
      note: json['note'],
      status: json['status'] ?? 'PENDING',
      rejectReason: json['reject_reason'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
