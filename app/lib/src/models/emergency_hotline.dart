class EmergencyHotline {
  final int id;
  final String name;
  final String department;
  final String number;
  final String? description;
  final bool isActive;
  final int priorityOrder;

  EmergencyHotline({
    required this.id,
    required this.name,
    required this.department,
    required this.number,
    this.description,
    required this.isActive,
    required this.priorityOrder,
  });

  factory EmergencyHotline.fromJson(Map<String, dynamic> json) {
    return EmergencyHotline(
      id: json['id'],
      name: json['name'],
      department: json['department'],
      number: json['number'],
      description: json['description'],
      isActive: json['is_active'],
      priorityOrder: json['priority_order'],
    );
  }
} 