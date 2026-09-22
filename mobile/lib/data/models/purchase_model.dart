class PurchaseModel {
  final int id;
  final int courseId;
  final String courseName;
  final int? specializationId;
  final String? specializationName;
  final int? year;
  final String? teacherName;
  final String pricePaid;
  final String teacherShare;
  final DateTime? createdAt;
  final int? lecturesCount;

  PurchaseModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    this.specializationId,
    this.specializationName,
    this.year,
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
      specializationId: json['specialization_id'],
      specializationName: json['specialization_name'],
      year: json['year'],
      teacherName: json['teacher_full_name'] ?? json['teacher_name'],
      pricePaid: (json['price_paid'] ?? json['price'] ?? '0.00').toString(),
      teacherShare: (json['teacher_share'] ?? '0.00').toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      lecturesCount: json['lectures_count'],
    );
  }

  PurchaseModel withSpecializationName(String name) {
    return PurchaseModel(
      id: id,
      courseId: courseId,
      courseName: courseName,
      specializationId: specializationId,
      specializationName: name,
      year: year,
      teacherName: teacherName,
      pricePaid: pricePaid,
      teacherShare: teacherShare,
      createdAt: createdAt,
      lecturesCount: lecturesCount,
    );
  }
}
