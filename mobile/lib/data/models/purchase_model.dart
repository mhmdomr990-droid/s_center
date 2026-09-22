class PurchaseModel {
  final int id;
  final int courseId;
  final String courseName;
  final String? specializationName;
  final String? teacherName;
  final String pricePaid;
  final String teacherShare;
  final DateTime? createdAt;
  final int? lecturesCount;

  PurchaseModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    this.specializationName,
    this.teacherName,
    required this.pricePaid,
    required this.teacherShare,
    this.createdAt,
    this.lecturesCount,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? json['id'] ?? 0,
      courseName: json['course_name'] ?? json['name'] ?? '',
      specializationName: json['specialization_name'],
      teacherName: json['teacher_full_name'] ?? json['teacher_name'],
      pricePaid: (json['price_paid'] ?? json['price'] ?? '0.00').toString(),
      teacherShare: (json['teacher_share'] ?? '0.00').toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      lecturesCount: json['lectures_count'],
    );
  }
}
