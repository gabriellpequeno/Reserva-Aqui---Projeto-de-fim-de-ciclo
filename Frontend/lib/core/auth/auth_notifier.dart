import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/data/services/fcm_token_service.dart';
import 'auth_state.dart';

final _baseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

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
    _registerFcmToken(role);
  }

  Future<void> clear() async {
    final current = state.asData?.value;

    if (current?.role != null) _removeFcmToken(current!.role!);
    if (current?.refreshToken != null && current?.role != null) {
      _callLogoutEndpoint(current!.role!, current.refreshToken!);
    }

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessKey),
      prefs.remove(_refreshKey),
      prefs.remove(_roleKey),
    ]);
    state = const AsyncData(AuthState());
  }

  void _callLogoutEndpoint(AuthRole role, String refreshToken) {
    final path = role == AuthRole.host ? '/hotel/logout' : '/usuarios/logout';
    Dio(BaseOptions(baseUrl: _baseUrl))
        .post(path, data: {'refreshToken': refreshToken})
        .catchError((_) {});
  }

  Future<void> _registerFcmToken(AuthRole role) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(fcmTokenServiceProvider).register(token, role);
      }
    } catch (_) {}
  }

  Future<void> _removeFcmToken(AuthRole role) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ref.read(fcmTokenServiceProvider).remove(token, role);
      }
    } catch (_) {}
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
