class SpecializationModel {
  final int id;
  final String name;
  final bool isPublished;
  final int sortOrder;

  SpecializationModel({
    required this.id,
    required this.name,
    required this.isPublished,
    required this.sortOrder,
  });

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      isPublished: json['is_published'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
