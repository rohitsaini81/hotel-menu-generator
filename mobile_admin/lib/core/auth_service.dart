import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../models/auth_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class AuthService {
  static bool _didInit = false;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
    clientId: kIsWeb && ApiConfig.googleClientId.isNotEmpty
        ? ApiConfig.googleClientId
        : null,
    serverClientId:
        ApiConfig.googleClientId.isNotEmpty ? ApiConfig.googleClientId : null,
  );

  static Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  static Future<void> ensureInitialized() async {
    if (_didInit) {
      return;
    }
    _didInit = true;
    if (kIsWeb) {
      await GoogleSignInPlatform.instance.initWithParams(
        SignInInitParameters(
          clientId:
              ApiConfig.googleClientId.isEmpty ? null : ApiConfig.googleClientId,
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
    return ApiClient.loginWithGoogle(idToken);
  }

  static Future<AuthResponse> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }
    return authenticateAccount(account);
  }
}
