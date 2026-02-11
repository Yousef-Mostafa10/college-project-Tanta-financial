class TransactionType {
  final String name;
  final String creatorName;

  TransactionType({
    required this.name,
    required this.creatorName,
  });

  factory TransactionType.fromJson(Map<String, dynamic> json) {
    return TransactionType(
      name: json['name'] as String? ?? 'Unknown',
      creatorName: json['creatorName'] as String? ?? 'System',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'creatorName': creatorName,
    };
  }
}
