class LectureModel {
  final int id;
  final int courseId;
  final String? courseName;
  final String title;
  final String type;
  final String? url;
  final String? content;
  final bool isPublished;
  final int sortOrder;
  final int? createdBy;
  final DateTime? createdAt;

  LectureModel({
    required this.id,
    required this.courseId,
    this.courseName,
    required this.title,
    required this.type,
    this.url,
    this.content,
    required this.isPublished,
    required this.sortOrder,
    this.createdBy,
    this.createdAt,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    return LectureModel(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? json['course']?['id'] ?? 0,
      courseName: json['course_name'] ?? json['course']?['name'],
      title: json['title'] ?? '',
      type: json['type'] ?? 'TEXT',
      url: json['url'],
      content: json['content'],
      isPublished: json['is_published'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdBy: json['created_by'] ?? json['createdBy']?['id'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  bool get isVideo => type == 'VIDEO';
  bool get isPdf => type == 'PDF';
  bool get isText => type == 'TEXT';

  String get typeIcon {
    switch (type) {
      case 'VIDEO':
        return '🎬';
      case 'PDF':
        return '📄';
      case 'TEXT':
        return '📝';
      default:
        return '📎';
    }
  }
}
