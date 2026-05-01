import 'package:flutter/foundation.dart';

enum AuthRole { guest, host, admin }

@immutable
class AuthState {
  const AuthState({this.accessToken, this.refreshToken, this.role});

  final String? accessToken;
  final String? refreshToken;
  final AuthRole? role;

  bool get isAuthenticated => accessToken != null && role != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    AuthRole? role,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      role: role ?? this.role,
    );
  }
}
