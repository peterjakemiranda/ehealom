import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import '../models/resource.dart';
import '../config/constants.dart';
import 'auth_service.dart';

class ResourceService {
  final AuthService _authService = AuthService();
  late final http.Client _client;

  ResourceService() {
    if (kDebugMode) {
      final httpClient = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      _client = IOClient(httpClient);
    } else {
      _client = http.Client();
    }
  }

  Future<Map<String, dynamic>> fetchResources({
    int page = 1,
    String? category,
    String? search,
    int perPage = 10,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/resources').replace(
        queryParameters: queryParams,
      );

      debugPrint('Fetching resources with URL: $url');

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Resources response: $data');
        return {
          'data': data['data'] as List,
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching resources: $e');
      rethrow;
    }
  }

  Future<Resource> createResource(Map<String, dynamic> resource, File? file) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/resources'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      resource.forEach((key, value) {
        if (key == 'is_published') {
          request.fields[key] = (value as bool) ? '1' : '0';
        } else {
          request.fields[key] = value.toString();
        }
      });

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Resource.fromJson(data['data']);
      } else {
        throw Exception('Failed to create resource: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Resource> updateResource(String uuid, Map<String, dynamic> resource, File? file) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/resources/$uuid'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';

      resource.forEach((key, value) {
        if (key == 'is_published') {
          request.fields[key] = (value as bool) ? '1' : '0';
        } else if (key != 'uuid' && key != 'localId') {
          request.fields[key] = value.toString();
        }
      });

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Resource.fromJson(data['data']);
      } else {
        throw Exception('Failed to update resource: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteResource(String uuid) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/resources/$uuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete resource: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchResource(String uuid) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final url = Uri.parse('${ApiConfig.baseUrl}/resources/$uuid');
      
      debugPrint('🌐 Fetching resource URL: $url');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('📥 Resource Response Status: ${response.statusCode}');
      debugPrint('📥 Resource Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load resource: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error in fetchResource: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }
} 