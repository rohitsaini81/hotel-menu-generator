class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.picture,
  });

  final String id;
  final String email;
  final String name;
  final String picture;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      picture: json['picture']?.toString() ?? '',
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
  });

  final String token;
  final AuthUser user;
  final String expiresAt;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token']?.toString() ?? '',
      user: AuthUser.fromJson(
        (json['user'] as Map<String, dynamic>? ?? {}),
      ),
      expiresAt: json['expiresAt']?.toString() ?? '',
    );
  }
}
