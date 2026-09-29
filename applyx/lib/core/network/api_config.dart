import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    // Return API_BASE_URL from .env if it exists
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    }
    // Default fallback for Android Emulator local development
    return 'http://10.0.2.2:8000/api/v1';
  }
}
