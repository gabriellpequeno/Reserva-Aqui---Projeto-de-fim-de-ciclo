class AuthResponse {
  final String accessToken;
  final String refreshToken;

  const AuthResponse({required this.accessToken, required this.refreshToken});

  // O backend retorna { tokens: { accessToken, refreshToken } }
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    return AuthResponse(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }
}
