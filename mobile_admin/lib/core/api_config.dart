import '../web_client_id.dart';

class ApiConfig {
  static const baseUrl = 'https://hotel-menu-generator.onrender.com';
  // static const baseUrl = 'http://127.0.0.1:5000';

  static String get googleClientId {
    const envClientId =
        String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (envClientId.isNotEmpty) {
      return envClientId;
    }
    final webClientId = readWebClientId();
    return webClientId ?? '';
  }
}
