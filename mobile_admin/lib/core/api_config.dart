import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../web_client_id.dart';

class ApiConfig {
  static const _defaultBaseUrl = 'https://hotel-menu-generator.onrender.com';
  static const _devBaseUrl = 'http://127.0.0.1:5000';
  static const _devAndroidEmulatorBaseUrl = 'http://10.0.2.2:5000';
  static const _defaultGoogleClientId = '';

  static bool get isDevMode {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: '');
    const devFlag = bool.fromEnvironment('DEV', defaultValue: false);
    return devFlag || appEnv.toLowerCase() == 'dev';
  }

  static String _resolveDevBaseUrl() {
    if (kIsWeb) {
      return _devBaseUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _devAndroidEmulatorBaseUrl;
    }
    return _devBaseUrl;
  }

  static String get baseUrl {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    final dotenvBaseUrl = dotenv.env['API_BASE_URL'];
    if (dotenvBaseUrl != null && dotenvBaseUrl.isNotEmpty) {
      return dotenvBaseUrl;
    }
    if (isDevMode) {
      return _resolveDevBaseUrl();
    }
    return _defaultBaseUrl;
  }

  static String get googleClientId {
    const envClientId = String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '',
    );
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
