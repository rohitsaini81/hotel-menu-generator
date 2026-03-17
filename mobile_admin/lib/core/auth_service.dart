import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../models/auth_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class SessionProfile {
  const SessionProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.number,
    required this.picture,
    this.isTester = false,
  });

  final String id;
  final String name;
  final String email;
  final String number;
  final String picture;
  final bool isTester;
}

class AuthService {
  static bool _didInit = false;
  static SessionProfile? _currentProfile;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
    clientId: kIsWeb && ApiConfig.googleClientId.isNotEmpty
        ? ApiConfig.googleClientId
        : null,
    serverClientId: ApiConfig.googleClientId.isNotEmpty
        ? ApiConfig.googleClientId
        : null,
  );

  static Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;
  static SessionProfile? get currentProfile => _currentProfile;

  static Future<void> ensureInitialized() async {
    if (_didInit) {
      return;
    }
    _didInit = true;
    if (kIsWeb) {
      await GoogleSignInPlatform.instance.initWithParams(
        SignInInitParameters(
          clientId: ApiConfig.googleClientId.isEmpty
              ? null
              : ApiConfig.googleClientId,
          scopes: const ['email', 'profile', 'openid'],
        ),
      );
    }
    await _googleSignIn.signInSilently();
  }

  static Future<AuthResponse> authenticateAccount(
    GoogleSignInAccount account,
  ) async {
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Missing Google id token');
    }
    final response = await ApiClient.loginWithGoogle(idToken);
    _currentProfile = SessionProfile(
      id: response.user.id.isNotEmpty ? response.user.id : account.id,
      name: response.user.name.isNotEmpty
          ? response.user.name
          : (account.displayName ?? 'Google user'),
      email: response.user.email.isNotEmpty
          ? response.user.email
          : account.email,
      number: 'Not provided by Google',
      picture: response.user.picture.isNotEmpty
          ? response.user.picture
          : (account.photoUrl ?? ''),
    );
    return response;
  }

  static Future<AuthResponse> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }
    return authenticateAccount(account);
  }

  static void signInAsTester() {
    _currentProfile = const SessionProfile(
      id: 'tester',
      name: 'Test',
      email: 'test@email.com',
      number: '99999',
      picture: '',
      isTester: true,
    );
  }
}
