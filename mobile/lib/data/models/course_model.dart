class CourseModel {
  final int id;
  final int specializationId;
  final String specializationName;
  final int? teacherId;
  final String? teacherName;
  final String teacherPercent;
  final int year;
  final String name;
  final String? description;
  final String price;
  final bool isPublished;
  final int sortOrder;
  final int? purchasesCount;
  final bool isPurchased;

  CourseModel({
    required this.id,
    required this.specializationId,
    required this.specializationName,
    this.teacherId,
    this.teacherName,
    required this.teacherPercent,
    required this.year,
    required this.name,
    this.description,
    required this.price,
    required this.isPublished,
    required this.sortOrder,
    this.purchasesCount,
    this.isPurchased = false,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] ?? 0,
      specializationId: json['specialization_id'] ?? 0,
      specializationName: json['specialization_name'] ?? json['specialization']?['name'] ?? '',
      teacherId: json['teacher_id'] ?? json['teacher']?['id'],
      teacherName: json['teacher_full_name'] ?? json['teacher']?['full_name'],
      teacherPercent: (json['teacher_percent'] ?? '0.00').toString(),
      year: json['year'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? '0.00').toString(),
      isPublished: json['is_published'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      purchasesCount: json['purchases_count'],
      isPurchased: json['purchased'] ?? false,
    );
  }
}
