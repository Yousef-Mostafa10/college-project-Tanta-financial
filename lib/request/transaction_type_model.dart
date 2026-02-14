class TransactionType {
  final String name;
  final int? creatorId;
  final String creatorName; // kept for backward compatibility in UI

  TransactionType({
    required this.name,
    this.creatorId,
    this.creatorName = '',
  });

  factory TransactionType.fromJson(Map<String, dynamic> json) {
    return TransactionType(
      name: json['name'] as String? ?? 'Unknown',
      creatorId: json['creatorId'] is int ? json['creatorId'] : (json['creatorId'] != null ? int.tryParse(json['creatorId'].toString()) : null),
      creatorName: json['creatorName'] as String? ?? (json['creatorId'] != null ? 'User #${json['creatorId']}' : 'System'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (creatorId != null) 'creatorId': creatorId,
    };
  }
}
