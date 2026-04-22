import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';

const _baseUrl = 'http://localhost:3000/api/v1';

// Dio separado exclusivamente para chamadas de refresh — evita loop de interceptor.
final _refreshDio = Dio(
  BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ),
);

bool _isRefreshing = false;
final _pendingQueue =
    <({RequestOptions options, ErrorInterceptorHandler handler})>[];

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final auth = ref.read(authProvider).asData?.value;
        if (auth?.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${auth!.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final auth = ref.read(authProvider).asData?.value;

        if (error.response?.statusCode != 401 || auth?.refreshToken == null) {
          if (error.response?.statusCode == 401) {
            await ref.read(authProvider.notifier).clear();
          }
          handler.next(error);
          return;
        }

        if (_isRefreshing) {
          _pendingQueue.add((options: error.requestOptions, handler: handler));
          return;
        }

        _isRefreshing = true;
        try {
          final refreshEndpoint = auth!.role == AuthRole.host
              ? '/hotel/refresh'
              : '/usuarios/refresh';

          final res = await _refreshDio.post<Map<String, dynamic>>(
            refreshEndpoint,
            data: {'refreshToken': auth.refreshToken},
          );

          final tokens = res.data!['tokens'] as Map<String, dynamic>;
          final newAccess = tokens['accessToken'] as String;
          final newRefresh = tokens['refreshToken'] as String;

          await ref
              .read(authProvider.notifier)
              .setAuth(newAccess, newRefresh, auth.role!);

          for (final pending in _pendingQueue) {
            pending.options.headers['Authorization'] = 'Bearer $newAccess';
            dio
                .fetch(pending.options)
                .then(
                  (r) => pending.handler.resolve(r),
                  onError: (e) => pending.handler.reject(e as DioException),
                );
          }
          _pendingQueue.clear();

          error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          handler.resolve(await dio.fetch(error.requestOptions));
        } catch (_) {
          _pendingQueue.clear();
          await ref.read(authProvider.notifier).clear();
          handler.next(error);
        } finally {
          _isRefreshing = false;
        }
      },
    ),
  );

  return dio;
});
