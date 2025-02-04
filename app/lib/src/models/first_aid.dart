class FirstAid {
  final int id;
  final String title;
  final String content;
  final String icon;
  final int priorityOrder;
  final bool isActive;

  FirstAid({
    required this.id,
    required this.title,
    required this.content,
    required this.icon,
    required this.priorityOrder,
    required this.isActive,
  });

  factory FirstAid.fromJson(Map<String, dynamic> json) {
    return FirstAid(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      icon: json['icon'] ?? '',
      priorityOrder: json['priority_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
} 