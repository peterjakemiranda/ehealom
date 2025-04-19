import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class SettingsService {
  final _client = http.Client();
  
  Future<String> getTermsAndConditions() async {
    try {
      debugPrint('Fetching terms and conditions from: ${ApiConfig.baseUrl}/settings/terms');
      
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/settings/terms'),
        headers: {
          'Accept': 'application/json',
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['terms_and_conditions'] ?? 'Terms and conditions not available.';
      } else {
        throw Exception('Failed to load terms and conditions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to fetch terms and conditions: $e');
      return 'Failed to load terms and conditions. Please try again later.';
    }
  }
} 