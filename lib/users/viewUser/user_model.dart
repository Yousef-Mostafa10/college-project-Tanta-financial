class User {
  final String name;
  final String group;
  final String createdAt;
  final String updatedAt;

  User({
    required this.name,
    required this.group,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json["name"] ?? "Unknown",
      group: json["group"] ?? "user",
      createdAt: json["createdAt"] ?? "",
      updatedAt: json["updatedAt"] ?? json["createdAt"] ?? "",
    );
  }
}