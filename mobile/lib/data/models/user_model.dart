class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isTest;
  final String? balance;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isTest,
    this.balance,
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
    );
  }

  bool get isStudent => role == 'STUDENT';
  bool get isTeacher => role == 'TEACHER';
}
