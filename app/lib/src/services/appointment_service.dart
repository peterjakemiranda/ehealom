import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import '../models/appointment.dart';
import '../config/constants.dart';
import 'auth_service.dart';

class AppointmentService {
  final AuthService _authService = AuthService();
  late final http.Client _client;

  AppointmentService() {
    HttpClient client = HttpClient()
      ..badCertificateCallback = ((cert, host, port) => true);
    _client = IOClient(client);
  }

  Future<Map<String, dynamic>> fetchAppointments({
    String? status,
    String? date,
    int page = 1,
    int perPage = 10,
    bool upcoming = false,
    String? userType,
    String? department,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null) 'status': status,
        if (date != null) 'date': date,
        if (upcoming) 'upcoming': 'true',
        if (userType != null && userType != 'all') 'user_type': userType,
        if (department != null) 'department': department,
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/appointments').replace(
        queryParameters: queryParams,
      );

      debugPrint('🌐 Fetching appointments URL: $url');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Appointments Response Status: ${response.statusCode}');
      debugPrint('📥 Appointments Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'data': data['data'] as List,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load appointments: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error in fetchAppointments: $e');
      rethrow;
    }
  }

  Future<void> createAppointment(Map<String, dynamic> data) async {
    try {
      debugPrint('📤 Creating appointment with data: $data');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      debugPrint('🔑 Using token: $token');
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/appointments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      debugPrint('📥 Create Appointment Response Status: ${response.statusCode}');
      debugPrint('📥 Create Appointment Response Body: ${response.body}');

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create appointment');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating appointment: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Appointment> updateAppointment(String uuid, Map<String, dynamic> appointment) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/appointments/$uuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(appointment),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Appointment.fromJson(data['data']);
      } else {
        throw Exception('Failed to update appointment: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> fetchAvailableSlots({
    required String counselorId,
    required String date,
  }) async {
    try {
      debugPrint('🔍 Fetching time slots for counselor: $counselorId, date: $date');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/available-slots').replace(
          queryParameters: {
            'counselor_id': counselorId,
            'date': date,
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Time Slots Response Status: ${response.statusCode}');
      debugPrint('📥 Time Slots Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['slots'] ?? []);
      } else {
        throw Exception('Failed to load time slots: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching time slots: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCounselors() async {
    try {
      debugPrint('🔍 Fetching counselors...');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/users').replace(
          queryParameters: {'user_type': 'counselor'},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Counselors Response Status: ${response.statusCode}');
      debugPrint('📥 Counselors Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load counselors: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching counselors: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, int>> getAppointmentCounts() async {
    try {
      debugPrint('🔍 Fetching appointment counts...');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/counts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Appointment Counts Response Status: ${response.statusCode}');
      debugPrint('📥 Appointment Counts Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'upcoming': data['upcoming'] ?? 0,
          'pending': data['pending'] ?? 0,
          'past': data['past'] ?? 0,
          'cancelled': data['cancelled'] ?? 0,
        };
      } else {
        throw Exception('Failed to load appointment counts: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching appointment counts: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateStatus(String appointmentUuid, String status) async {
    try {
      debugPrint('📤 Updating appointment status - UUID: $appointmentUuid, New Status: $status');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentUuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      debugPrint('📥 Update Status Response Code: ${response.statusCode}');
      debugPrint('📥 Update Status Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update appointment status');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating appointment status: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/users/search-students').replace(
          queryParameters: {'query': query},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to search students: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error searching students: $e');
      rethrow;
    }
  }

  Future<List<String>> getDepartments() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token found');

      debugPrint('🔍 Fetching departments...');
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/departments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Departments Response Status: ${response.statusCode}');
      debugPrint('📥 Departments Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((dept) => dept.toString()).toList();
      } else {
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching departments: $e');
      rethrow;
    }
  }
} 