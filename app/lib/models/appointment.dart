class Appointment {
  final String id;
  final String uuid;
  final String studentId;
  final String counselorId;
  final DateTime appointmentDate;
  final String status;
  final String reason;
  final String? notes;
  final String locationType;
  final String? location;
  final Map<String, dynamic>? counselor;
  final Map<String, dynamic>? student;

  Appointment({
    required this.id,
    required this.uuid,
    required this.studentId,
    required this.counselorId,
    required this.appointmentDate,
    required this.status,
    required this.reason,
    this.notes,
    required this.locationType,
    this.location,
    this.counselor,
    this.student,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'].toString(),
      uuid: json['uuid'],
      studentId: json['student_id'].toString(),
      counselorId: json['counselor_id'].toString(),
      appointmentDate: DateTime.parse(json['appointment_date']),
      status: json['status'],
      reason: json['reason'],
      notes: json['notes'],
      locationType: json['location_type'] ?? 'online',
      location: json['location'],
      counselor: json['counselor'],
      student: json['student'],
    );
  }
} 