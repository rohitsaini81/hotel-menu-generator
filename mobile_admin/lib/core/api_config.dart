import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../web_client_id.dart';

class ApiConfig {
  static const _defaultBaseUrl = 'https://hotel-menu-generator.onrender.com';
  static const _defaultGoogleClientId = '';

  static String get baseUrl {
    const envBaseUrl =
        String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    final dotenvBaseUrl = dotenv.env['API_BASE_URL'];
    if (dotenvBaseUrl != null && dotenvBaseUrl.isNotEmpty) {
      return dotenvBaseUrl;
    }
    return _defaultBaseUrl;
  }

  static String get googleClientId {
    const envClientId =
        String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (envClientId.isNotEmpty) {
      return envClientId;
    }
    final dotenvClientId = dotenv.env['GOOGLE_CLIENT_ID'];
    if (dotenvClientId != null && dotenvClientId.isNotEmpty) {
      return dotenvClientId;
    }
    final webClientId = readWebClientId();
    return webClientId ?? _defaultGoogleClientId;
  }
}
