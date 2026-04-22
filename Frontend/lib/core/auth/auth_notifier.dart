import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _roleKey = 'auth_role';

  @override
  Future<AuthState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);
    final roleStr = prefs.getString(_roleKey);

    if (access == null || refresh == null || roleStr == null) {
      return const AuthState();
    }

    final role = AuthRole.values.where((r) => r.name == roleStr).firstOrNull;
    if (role == null) return const AuthState();

    return AuthState(accessToken: access, refreshToken: refresh, role: role);
  }

  Future<void> setAuth(
    String accessToken,
    String refreshToken,
    AuthRole role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_accessKey, accessToken),
      prefs.setString(_refreshKey, refreshToken),
      prefs.setString(_roleKey, role.name),
    ]);
    state = AsyncData(
      AuthState(accessToken: accessToken, refreshToken: refreshToken, role: role),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessKey),
      prefs.remove(_refreshKey),
      prefs.remove(_roleKey),
    ]);
    state = const AsyncData(AuthState());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
