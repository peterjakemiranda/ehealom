class Alert {
  final int id;
  final String title;
  final String content;
  final String type;
  final String notificationType;
  final String? department;
  final bool isActive;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.notificationType,
    this.department,
    required this.isActive,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      notificationType: json['notification_type'],
      department: json['department'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
} 