class User {
  final int? id;
  final String name;
  final String role;
  final bool active;
  final String? departmentName;
  final String createdAt;
  final String lastLogin;

  User({
    this.id,
    required this.name,
    required this.role,
    required this.active,
    this.departmentName,
    required this.createdAt,
    required this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // lastLogin can be a string, object, or null in the new API
    String lastLoginStr = "";
    if (json["lastLogin"] != null) {
      if (json["lastLogin"] is String) {
        lastLoginStr = json["lastLogin"];
      } else {
        lastLoginStr = json["lastLogin"].toString();
      }
    } else {
      lastLoginStr = json["createdAt"] ?? "";
    }

    return User(
      id: json["id"] is int ? json["id"] : (json["id"] != null ? int.tryParse(json["id"].toString()) : null),
      name: json["name"] ?? "Unknown",
      role: json["role"] ?? "user",
      active: json["active"] ?? true,
      departmentName: json["departmentName"],
      createdAt: json["createdAt"] ?? "",
      lastLogin: lastLoginStr,
    );
  }
}
