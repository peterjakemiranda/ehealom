import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';

/// Service to handle API requests to the backend
class ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = Environment.apiUrl;
  
  /// Get the stored auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  /// Set default headers with authentication if token is available
  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (withAuth) {
      String? token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  /// Make a GET request to the API
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      final headers = await _getHeaders(withAuth: withAuth);
      
      final response = await http.get(uri, headers: headers);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Make a POST request to the API
  Future<dynamic> post(String endpoint, {dynamic data, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(withAuth: withAuth);
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Make a PUT request to the API
  Future<dynamic> put(String endpoint, {dynamic data, bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(withAuth: withAuth);
      
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Make a DELETE request to the API
  Future<dynamic> delete(String endpoint, {bool withAuth = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(withAuth: withAuth);
      
      final response = await http.delete(uri, headers: headers);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  /// Handle API response and parse JSON
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body.isNotEmpty ? json.decode(response.body) : null;
    
    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else {
      final message = responseBody != null && responseBody.containsKey('message')
          ? responseBody['message']
          : 'Unknown error occurred';
          
      throw Exception('API Error ($statusCode): $message');
    }
  }
} 