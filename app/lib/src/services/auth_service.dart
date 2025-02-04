import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  late final http.Client _client;
  final _storage = const FlutterSecureStorage();

  AuthService() {
    if (kDebugMode) {
      final httpClient = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true); // Accept all certificates in debug
      _client = IOClient(httpClient);
    } else {
      _client = http.Client();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('Attempting login for email: $email');
    debugPrint('Login URL: ${ApiConfig.login}');
    
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.login),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));  // Add timeout

      debugPrint('Login Response Status: ${response.statusCode}');
      debugPrint('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        return data;
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (e is SocketException) {
        throw Exception('Cannot connect to campus-emergency.io - Please check your connection');
      }
      if (e is HandshakeException) {
        throw Exception('SSL Error - Please ensure you have the proper certificates installed');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    debugPrint('Getting current user with token: ${token?.substring(0, 10)}...');
    
    if (token == null) {
      debugPrint('No token found');
      throw Exception('No token found');
    }

    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.me),
        headers: _authHeaders(token),
      );

      debugPrint('Get User Response Status: ${response.statusCode}');
      debugPrint('Get User Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user data: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get User Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔐 AuthService: Starting logout');
      final token = await getToken();
      if (token == null) throw Exception('No token found');

      final response = await _client.post(
        Uri.parse(ApiConfig.logout),  // Using the correct endpoint from constants
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📤 Logout response status: ${response.statusCode}');
      debugPrint('📤 Logout response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Logout failed: ${response.statusCode}');
      }

      // Clear stored token and data
      await _storage.delete(key: StorageKeys.authToken);
      await _storage.delete(key: StorageKeys.userData);
      
    } catch (e) {
      debugPrint('❌ AuthService logout error: $e');
      // Still clear storage on error
      await _storage.delete(key: StorageKeys.authToken);
      await _storage.delete(key: StorageKeys.userData);
      rethrow;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.authToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.authToken);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
  }

  // Update headers to include Accept header for Sanctum
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String userType,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.register),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'user_type': userType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await getToken();
    if (token == null) throw Exception('No token found');

    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: _authHeaders(token),
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }

    return jsonDecode(response.body);
  }
}
