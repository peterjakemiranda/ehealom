class Appointment {
  final String id;
  final String uuid;
  final String studentId;
  final Map<String, dynamic>? counselor;
  final DateTime appointmentDate;
  final String status;
  final String reason;
  final String locationType;
  final String? location;
  final String? notes;
  final Map<String, dynamic>? student;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userType;

  Appointment({
    required this.id,
    required this.uuid,
    required this.studentId,
    this.counselor,
    required this.appointmentDate,
    required this.status,
    required this.reason,
    required this.locationType,
    this.location,
    this.notes,
    this.student,
    this.createdAt,
    this.updatedAt,
    this.userType,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      counselor: json['counselor'] as Map<String, dynamic>?,
      appointmentDate: json['appointment_date'] != null 
          ? DateTime.parse(json['appointment_date']) 
          : DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      reason: json['reason']?.toString() ?? '',
      locationType: json['location_type']?.toString() ?? 'online',
      location: json['location']?.toString(),
      notes: json['notes']?.toString(),
      student: json['student'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      userType: json['user_type']?.toString(),
    );
  }
} 