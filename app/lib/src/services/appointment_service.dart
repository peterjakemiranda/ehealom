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
    if (kDebugMode) {
      final httpClient = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      _client = IOClient(httpClient);
    } else {
      _client = http.Client();
    }
  }

  Future<Map<String, dynamic>> fetchAppointments({
    String? status,
    String? date,
    int page = 1,
    int perPage = 10,
    bool upcoming = false,
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
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/appointments').replace(
        queryParameters: queryParams,
      );

      // Debug log
      debugPrint('🌐 Fetching appointments: $url');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Debug log
      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'appointments': (data['data'] as List)
              .map((json) => Appointment.fromJson(json))
              .toList(),
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

  Future<Appointment> createAppointment(Map<String, dynamic> appointment) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/appointments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(appointment),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Appointment.fromJson(data['data']);
      } else {
        throw Exception('Failed to create appointment: ${response.statusCode}');
      }
    } catch (e) {
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

  Future<List<Map<String, dynamic>>> fetchAvailableSlots({
    required String counselorId,
    required String date,
  }) async {
    try {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['slots']);
      } else {
        throw Exception('Failed to load time slots: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCounselors() async {
    try {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load counselors: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
} 