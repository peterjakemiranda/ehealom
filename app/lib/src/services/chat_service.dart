import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final _authService = AuthService();
  final _client = http.Client();

  Future<Map<String, dynamic>> getMessages({int page = 1}) async {
    try {
      debugPrint('🔄 ChatService: Fetching messages page $page...');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token found');

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/messages')
          .replace(queryParameters: {'page': page.toString()});
      debugPrint('📡 ChatService: GET request to $url');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 ChatService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Return the full pagination response
      } else {
        throw Exception('Failed to load messages: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ ChatService: Error getting messages - $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      debugPrint('📤 ChatService: Sending message...');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token found');

      final url = Uri.parse('${ApiConfig.baseUrl}/chat/messages');
      debugPrint('📡 ChatService: POST request to $url');
      
      final payload = {'message': message};
      debugPrint('📤 Request payload: $payload');

      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }
} 