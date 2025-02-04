import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapsConfig {
  static String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
} 