import 'package:dio/dio.dart';
import '../auth/auth_state.dart';

typedef AuthStateReader = AuthState? Function();
typedef TokensSaver = Future<void> Function(
  String accessToken,
  String refreshToken,
  AuthRole role,
);
typedef AuthClearer = Future<void> Function();

/// Lógica do refresh de token, isolada do `dioProvider` para permitir teste
/// unitário sem depender de Riverpod, SharedPreferences ou Firebase.
///
/// Contrato:
///   - Em qualquer 401 não-business e ainda não-retried, dispara um refresh.
///   - Apenas um refresh roda por vez; chamadas concorrentes entram em fila e
///     são re-executadas com o novo accessToken assim que o refresh termina.
///   - Se o refresh falhar, limpa a fila, dispara `clear()` e propaga o erro.
///   - 401 em endpoints "business" (`/login`, `/change-password`) não tenta
///     refresh — é credencial inválida, não token expirado.
///   - 401 num retry já refeito → token novo também rejeitado, faz `clear()`.
class AuthRefreshInterceptor {
  AuthRefreshInterceptor({
    required this.readAuth,
    required this.refreshDio,
    required this.saveTokens,
    required this.clearAuth,
  });

  final AuthStateReader readAuth;
  final Dio refreshDio;
  final TokensSaver saveTokens;
  final AuthClearer clearAuth;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _pendingQueue = [];

  /// `dio` é o cliente principal — usado para refazer as requests com o token novo.
  InterceptorsWrapper build(Dio dio) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final auth = readAuth();
        if (auth?.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${auth!.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) => _onError(dio, error, handler),
    );
  }

  Future<void> _onError(
    Dio dio,
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final auth = readAuth();
    final path = error.requestOptions.path;
    final isBusinessAuth =
        path.endsWith('/change-password') || path.endsWith('/login');
    final alreadyRetried = error.requestOptions.extra['_retried'] == true;

    if (error.response?.statusCode != 401 ||
        auth?.refreshToken == null ||
        isBusinessAuth ||
        alreadyRetried) {
      if (error.response?.statusCode == 401 &&
          !isBusinessAuth &&
          alreadyRetried) {
        await clearAuth();
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

      final res = await refreshDio.post<Map<String, dynamic>>(
        refreshEndpoint,
        data: {'refreshToken': auth.refreshToken},
      );

      final tokens = res.data!['tokens'] as Map<String, dynamic>;
      final newAccess = tokens['accessToken'] as String;
      final newRefresh = tokens['refreshToken'] as String;

      await saveTokens(newAccess, newRefresh, auth.role!);

      for (final pending in _pendingQueue) {
        pending.options.headers['Authorization'] = 'Bearer $newAccess';
        pending.options.extra['_retried'] = true;
        dio.fetch(pending.options).then(
              (r) => pending.handler.resolve(r),
              onError: (e) => pending.handler.reject(e as DioException),
            );
      }
      _pendingQueue.clear();

      error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      error.requestOptions.extra['_retried'] = true;
      handler.resolve(await dio.fetch(error.requestOptions));
    } catch (_) {
      _pendingQueue.clear();
      await clearAuth();
      handler.next(error);
    } finally {
      _isRefreshing = false;
    }
  }
}
