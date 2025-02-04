import 'env.dart';

class ApiConfig {
  static const String apiVersion = '/api';
  static final String baseUrl = '${Environment.apiBaseUrl}$apiVersion';
  
  // Auth endpoints
  static final String login = '$baseUrl/login';
  static final String register = '$baseUrl/register';
  static final String logout = '$baseUrl/logout';
  static final String me = '$baseUrl/me';
}

class StorageKeys {
  static const String authToken = 'auth_token';
  static const String tokenTimestamp = 'token_timestamp';
  static const String userData = 'user_data';
  // Add other storage keys here
}
