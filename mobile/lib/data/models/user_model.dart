class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isTest;
  final String? balance;
  final String? phone;
  final int? specializationId;
  final String? specializationName;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isTest,
    this.balance,
    this.phone,
    this.specializationId,
    this.specializationName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'STUDENT',
      isActive: json['is_active'] ?? true,
      isTest: json['is_test'] ?? false,
      balance: json['balance']?.toString(),
      phone: json['phone'] as String?,
      specializationId: (json['specialization_id'] as num?)?.toInt(),
      specializationName: json['specialization_name'] as String?,
    );
  }

  bool get isStudent => role == 'STUDENT';
  bool get isTeacher => role == 'TEACHER';
  bool get isAdmin => role == 'ADMIN';
}
