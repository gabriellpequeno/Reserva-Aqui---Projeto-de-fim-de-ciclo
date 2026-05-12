import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import 'auth_refresh_interceptor.dart';

const kBackendHost = String.fromEnvironment(
  'BACKEND_HOST',
  defaultValue: '',
);

// 1. BACKEND_HOST explícito sempre vence (staging, override manual)
// 2. kReleaseMode sem override → produção hardcoded
// 3. Fallback debug → emulador/web local
final backendHost = kBackendHost.isNotEmpty
    ? kBackendHost
    : kReleaseMode
        ? 'https://lab.alphaedtech.org.br/server04'
        : (kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000');

final _baseUrl = kBackendHost.isNotEmpty
    ? '$kBackendHost/api/v1'
    : kReleaseMode
        ? 'https://lab.alphaedtech.org.br/server04/api/v1'
        : (kIsWeb ? 'http://localhost:3000/api/v1' : 'http://10.0.2.2:3000/api/v1');

// Dio separado exclusivamente para chamadas de refresh — evita loop de interceptor.
final _refreshDio = Dio(
  BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final interceptor = AuthRefreshInterceptor(
    readAuth: () => ref.read(authProvider).asData?.value,
    refreshDio: _refreshDio,
    saveTokens: (a, r, role) =>
        ref.read(authProvider.notifier).setAuth(a, r, role),
    clearAuth: () => ref.read(authProvider.notifier).clear(),
  );

  dio.interceptors.add(interceptor.build(dio));
  return dio;
});
