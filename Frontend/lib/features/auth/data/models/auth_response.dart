class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String? papel; // 'usuario' | 'admin' (vem no response do login de usuário)

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    this.papel,
  });

  // O backend retorna { data: { ..., papel }, tokens: { accessToken, refreshToken } }
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    return AuthResponse(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      papel: data?['papel'] as String?,
    );
  }
}
