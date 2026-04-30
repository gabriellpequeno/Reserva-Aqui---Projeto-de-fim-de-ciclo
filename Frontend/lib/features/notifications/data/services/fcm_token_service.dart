import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/auth/auth_state.dart';

class FcmTokenService {
  FcmTokenService(this._dio);
  final Dio _dio;

  Future<void> register(String fcmToken, AuthRole role) async {
    final path = role == AuthRole.host
        ? '/dispositivos-fcm/hotel'
        : '/dispositivos-fcm/usuario';
    await _dio.post<void>(path, data: {
      'fcm_token': fcmToken,
      'origem': kIsWeb ? 'DASHBOARD_WEB' : 'APP_ANDROID',
    });
  }

  Future<void> remove(String fcmToken, AuthRole role) async {
    final path = role == AuthRole.host
        ? '/dispositivos-fcm/hotel'
        : '/dispositivos-fcm/usuario';
    await _dio.delete<void>(path, data: {'fcm_token': fcmToken});
  }
}

final fcmTokenServiceProvider = Provider<FcmTokenService>((ref) {
  return FcmTokenService(ref.watch(dioProvider));
});
