import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static const dev = 'dev';
  static const prod = 'prod';
  
  static late String currentEnvironment;
  static late String apiUrl;
  
  static Future<void> initialize(String environment) async {
    if (environment != dev && environment != prod) {
      throw ArgumentError('Environment must be either "dev" or "prod"');
    }
    
    // Then load the environment-specific .env file
    await dotenv.load(fileName: '.env.$environment');
    
    currentEnvironment = environment;
    debugPrint('Environment: Initialized with $environment environment');
    
    if (environment == dev) {
      apiUrl = 'http://localhost:8000'; // For emulator/local testing
      // apiUrl = 'http://10.0.2.2:8000'; // For Android emulator
    } else {
      apiUrl = 'https://api.ehealom.com'; // Production URL
    }
  }
  
  static bool get isDev => currentEnvironment == dev;
  static bool get isProd => currentEnvironment == prod;

  static String get apiBaseUrl {
    debugPrint('Environment: Using ${currentEnvironment} environment');
    return dotenv.env['API_BASE_URL'] ?? 'https://api.ehealom.live';
  }

  static String get openAiApiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in environment');
    }
    return key;
  }
}
