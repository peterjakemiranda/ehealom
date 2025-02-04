import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static const String dev = 'dev';
  static const String prod = 'prod';
  
  static String currentEnvironment = dev;
  
  static Future<void> initialize(String environment) async {
    if (environment != dev && environment != prod) {
      throw ArgumentError('Environment must be either "dev" or "prod"');
    }
    
    // Load the appropriate .env file
    await dotenv.load(fileName: '.env.$environment');
    
    currentEnvironment = environment;
    debugPrint('Environment: Initialized with $environment environment');
  }
  
  static String get apiBaseUrl {
    debugPrint('Environment: Using ${currentEnvironment} environment');
    return dotenv.env['API_BASE_URL'] ?? 'https://ehealom.io';
  }

  static String get openAiApiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in environment');
    }
    return key;
  }
}
