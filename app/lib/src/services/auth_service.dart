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
  // In-memory token storage
  static String? _inMemoryToken;

  AuthService() {
    HttpClient client = HttpClient()
      ..badCertificateCallback = ((cert, host, port) => true);
    _client = IOClient(client);
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
        throw Exception('Cannot connect to ${ApiConfig.baseUrl} - Please check your connection');
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
      await clearToken();
      await _storage.delete(key: StorageKeys.userData);
      
    } catch (e) {
      debugPrint('❌ AuthService logout error: $e');
      // Still clear storage on error
      await clearToken();
      await _storage.delete(key: StorageKeys.userData);
      rethrow;
    }
  }

  // Store token in memory only
  Future<void> _saveToken(String token) async {
    _inMemoryToken = token;
  }

  // Get token from memory only
  Future<String?> getToken() async {
    return _inMemoryToken;
  }

  // Clear the in-memory token
  Future<void> clearToken() async {
    _inMemoryToken = null;
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

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      debugPrint('🚀 AuthService: Starting registration with data: $userData');
      
      final response = await _client.post(
        Uri.parse(ApiConfig.register),
        headers: _headers,
        body: jsonEncode(userData),
      );

      debugPrint('📥 AuthService: Registration response status: ${response.statusCode}');
      debugPrint('📥 AuthService: Registration response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Registration failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      
      // Save token immediately after successful registration
      if (data['token'] != null) {
        debugPrint('🔑 AuthService: Saving token after registration');
        await _saveToken(data['token']);
      }

      return data;
    } catch (e) {
      debugPrint('❌ AuthService: Register Error: $e');
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

  Future<bool> updateFCMToken(String fcmToken) async {
    debugPrint('AuthService: Updating FCM token');
    final token = await getToken();
    
    if (token == null) {
      debugPrint('AuthService: Cannot update FCM token - user not logged in');
      return false;
    }
    
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/notification/token'),
        headers: _authHeaders(token),
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      
      if (response.statusCode == 200) {
        debugPrint('AuthService: FCM token updated successfully');
        return true;
      } else {
        debugPrint('AuthService: Failed to update FCM token - ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('AuthService: FCM token update error - $e');
      return false;
    }
  }
}
