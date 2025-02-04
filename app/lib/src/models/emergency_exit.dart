class EmergencyExit {
  final int id;
  final double latitude;
  final double longitude;
  final int floor;
  final String description;
  final String type; // stairs, door, etc.
  final bool isAccessible; // wheelchair accessible

  EmergencyExit({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.floor,
    required this.description,
    required this.type,
    required this.isAccessible,
  });

  factory EmergencyExit.fromJson(Map<String, dynamic> json) {
    return EmergencyExit(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      floor: json['floor'],
      description: json['description'],
      type: json['type'],
      isAccessible: json['is_accessible'],
    );
  }
} 