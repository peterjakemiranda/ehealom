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
    String? type,
    String? category,
    String? uuid,
    int perPage = 10,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/resources').replace(
        queryParameters: {
          'page': page.toString(),
          if (type != null) 'type': type,
          if (category != null) 'category': category,
          if (uuid != null) 'uuid': uuid,
          'per_page': perPage.toString(),
        },
      );

      // Log request
      debugPrint('🌐 GET $url');
      debugPrint('🔑 Token: ${await _authService.getToken()}');

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer ${await _authService.getToken()}',
          'Accept': 'application/json',
        },
      );

      // Log response
      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'resources': (data['data'] as List)
              .map((json) => Resource.fromJson(json))
              .toList(),
          'meta': data['meta'],
        };
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error in fetchResources: $e');
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
} 