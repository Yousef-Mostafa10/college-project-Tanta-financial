class User {
  final String name;
  final String role;
  final bool active;
  final String? departmentName;
  final String createdAt;
  final String lastLogin;

  User({
    required this.name,
    required this.role,
    required this.active,
    this.departmentName,
    required this.createdAt,
    required this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json["name"] ?? "Unknown",
      role: json["role"] ?? "user",
      active: json["active"] ?? true,
      departmentName: json["departmentName"],
      createdAt: json["createdAt"] ?? "",
      lastLogin: json["lastLogin"] ?? json["createdAt"] ?? "",
    );
  }
}