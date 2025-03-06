import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import 'auth_service.dart';

class CategoryService {
  final _authService = AuthService();
  final _client = http.Client();

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token found');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      rethrow;
    }
  }
} 