import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:reservaqui/core/auth/auth_state.dart';
import 'package:reservaqui/core/network/auth_refresh_interceptor.dart';

class _SaveTokensSpy {
  String? lastAccess;
  String? lastRefresh;
  AuthRole? lastRole;
  int calls = 0;

  Future<void> call(String a, String r, AuthRole role) async {
    lastAccess = a;
    lastRefresh = r;
    lastRole = role;
    calls++;
  }
}

class _ClearAuthSpy {
  int calls = 0;
  Future<void> call() async {
    calls++;
  }
}

({
  Dio dio,
  DioAdapter dioAdapter,
  Dio refreshDio,
  DioAdapter refreshAdapter,
  _SaveTokensSpy saveSpy,
  _ClearAuthSpy clearSpy,
}) buildHarness({required AuthState? Function() authReader}) {
  final dio = Dio();
  final dioAdapter = DioAdapter(dio: dio);

  final refreshDio = Dio();
  final refreshAdapter = DioAdapter(dio: refreshDio);

  final saveSpy = _SaveTokensSpy();
  final clearSpy = _ClearAuthSpy();

  final interceptor = AuthRefreshInterceptor(
    readAuth: authReader,
    refreshDio: refreshDio,
    saveTokens: saveSpy.call,
    clearAuth: clearSpy.call,
  );

  dio.interceptors.add(interceptor.build(dio));

  return (
    dio: dio,
    dioAdapter: dioAdapter,
    refreshDio: refreshDio,
    refreshAdapter: refreshAdapter,
    saveSpy: saveSpy,
    clearSpy: clearSpy,
  );
}

void main() {
  group('onRequest: anexa Authorization header quando há accessToken', () {
    test('inclui Bearer com accessToken atual', () async {
      AuthState? auth = const AuthState(
        accessToken: 'old-access',
        refreshToken: 'r1',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onGet('/me', (s) => s.reply(200, {'ok': true}));

      final res = await h.dio.get<dynamic>('/me');
      expect(res.statusCode, 200);

      // Inspeciona o header efetivamente enviado
      final sent = res.requestOptions.headers['Authorization'];
      expect(sent, 'Bearer old-access');
    });

    test('não inclui header quando não há auth', () async {
      final h = buildHarness(authReader: () => null);
      h.dioAdapter.onGet('/public', (s) => s.reply(200, {'ok': true}));

      final res = await h.dio.get<dynamic>('/public');
      expect(res.requestOptions.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('onError: 401 dispara refresh, salva tokens novos e refaz request', () {
    test('caminho feliz para AuthRole.guest usa /usuarios/refresh', () async {
      // Estado mutável: ponteiro vai apontar para tokens novos após o refresh.
      AuthState? auth = const AuthState(
        accessToken: 'expired',
        refreshToken: 'r1',
        role: AuthRole.guest,
      );

      final dio = Dio();
      final dioAdapter = DioAdapter(dio: dio);
      final refreshDio = Dio();
      final refreshAdapter = DioAdapter(dio: refreshDio);
      final saveSpy = _SaveTokensSpy();
      final clearSpy = _ClearAuthSpy();

      // saveTokens troca o estado E re-registra /profile como 200.
      Future<void> saveTokens(String a, String r, AuthRole role) async {
        await saveSpy.call(a, r, role);
        auth = AuthState(accessToken: a, refreshToken: r, role: role);
        dioAdapter.onGet('/profile', (s) => s.reply(200, {'name': 'Maria'}));
      }

      final interceptor = AuthRefreshInterceptor(
        readAuth: () => auth,
        refreshDio: refreshDio,
        saveTokens: saveTokens,
        clearAuth: clearSpy.call,
      );
      dio.interceptors.add(interceptor.build(dio));

      dioAdapter.onGet('/profile', (s) => s.reply(401, {'error': 'expired'}));
      refreshAdapter.onPost(
        '/usuarios/refresh',
        (s) => s.reply(200, {
          'tokens': {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
          },
        }),
        data: {'refreshToken': 'r1'},
      );

      final res = await dio.get<dynamic>('/profile');

      expect(res.statusCode, 200);
      expect(res.data, {'name': 'Maria'});
      expect(saveSpy.calls, 1);
      expect(saveSpy.lastAccess, 'new-access');
      expect(saveSpy.lastRefresh, 'new-refresh');
      expect(saveSpy.lastRole, AuthRole.guest);
      expect(clearSpy.calls, 0);
    });

    test('AuthRole.host usa /hotel/refresh', () async {
      AuthState? auth = const AuthState(
        accessToken: 'expired',
        refreshToken: 'r-host',
        role: AuthRole.host,
      );

      final dio = Dio();
      final dioAdapter = DioAdapter(dio: dio);
      final refreshDio = Dio();
      final refreshAdapter = DioAdapter(dio: refreshDio);
      final saveSpy = _SaveTokensSpy();
      final clearSpy = _ClearAuthSpy();

      Future<void> saveTokens(String a, String r, AuthRole role) async {
        await saveSpy.call(a, r, role);
        auth = AuthState(accessToken: a, refreshToken: r, role: role);
        dioAdapter.onGet('/dashboard', (s) => s.reply(200, {'ok': true}));
      }

      final interceptor = AuthRefreshInterceptor(
        readAuth: () => auth,
        refreshDio: refreshDio,
        saveTokens: saveTokens,
        clearAuth: clearSpy.call,
      );
      dio.interceptors.add(interceptor.build(dio));

      dioAdapter.onGet('/dashboard', (s) => s.reply(401, {}));
      // Importante: registra apenas /hotel/refresh — se chamar
      // /usuarios/refresh por engano, o adapter 404a e o teste falha.
      refreshAdapter.onPost(
        '/hotel/refresh',
        (s) => s.reply(200, {
          'tokens': {
            'accessToken': 'new-host-access',
            'refreshToken': 'new-host-refresh',
          },
        }),
        data: {'refreshToken': 'r-host'},
      );

      final res = await dio.get<dynamic>('/dashboard');
      expect(res.statusCode, 200);
      expect(saveSpy.lastRole, AuthRole.host);
    });
  });

  group('onError: caminhos que NÃO devem refazer refresh', () {
    test('401 em /login não dispara refresh (credencial errada)', () async {
      AuthState? auth = const AuthState(
        accessToken: 'a',
        refreshToken: 'r',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onPost('/login', (s) => s.reply(401, {'error': 'bad creds'}));

      await expectLater(
        h.dio.post<dynamic>('/login', data: {}),
        throwsA(isA<DioException>()),
      );
      expect(h.saveSpy.calls, 0);
      expect(h.clearSpy.calls, 0);
    });

    test('401 em /change-password não dispara refresh', () async {
      AuthState? auth = const AuthState(
        accessToken: 'a',
        refreshToken: 'r',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onPut(
        '/usuarios/change-password',
        (s) => s.reply(401, {'error': 'wrong current pw'}),
      );

      await expectLater(
        h.dio.put<dynamic>('/usuarios/change-password', data: {}),
        throwsA(isA<DioException>()),
      );
      expect(h.saveSpy.calls, 0);
    });

    test('erro não-401 (ex: 500) é propagado sem refresh', () async {
      AuthState? auth = const AuthState(
        accessToken: 'a',
        refreshToken: 'r',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onGet('/x', (s) => s.reply(500, {'error': 'boom'}));

      await expectLater(
        h.dio.get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(h.saveSpy.calls, 0);
      expect(h.clearSpy.calls, 0);
    });

    test('401 sem refreshToken não dispara refresh', () async {
      AuthState? auth = const AuthState(
        accessToken: 'a',
        refreshToken: null, // sem refresh
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onGet('/y', (s) => s.reply(401, {}));

      await expectLater(
        h.dio.get<dynamic>('/y'),
        throwsA(isA<DioException>()),
      );
      expect(h.saveSpy.calls, 0);
      expect(h.clearSpy.calls, 0);
    });
  });

  group('onError: refresh falhou', () {
    test('refresh 401 → clearAuth() e propaga erro original', () async {
      AuthState? auth = const AuthState(
        accessToken: 'expired',
        refreshToken: 'invalid-r',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onGet('/profile', (s) => s.reply(401, {}));
      h.refreshAdapter.onPost(
        '/usuarios/refresh',
        (s) => s.reply(401, {'error': 'invalid refresh'}),
        data: {'refreshToken': 'invalid-r'},
      );

      await expectLater(
        h.dio.get<dynamic>('/profile'),
        throwsA(isA<DioException>()),
      );
      expect(h.saveSpy.calls, 0);
      expect(h.clearSpy.calls, 1);
    });

    test('refresh com payload malformado → clearAuth()', () async {
      AuthState? auth = const AuthState(
        accessToken: 'expired',
        refreshToken: 'r1',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onGet('/profile', (s) => s.reply(401, {}));
      h.refreshAdapter.onPost(
        '/usuarios/refresh',
        (s) => s.reply(200, {'foo': 'bar'}), // sem 'tokens'
        data: {'refreshToken': 'r1'},
      );

      await expectLater(
        h.dio.get<dynamic>('/profile'),
        throwsA(isA<DioException>()),
      );
      expect(h.clearSpy.calls, 1);
    });
  });

  group('onError: retry já feito (alreadyRetried)', () {
    test('401 num retry com _retried=true não tenta refresh e dispara clear', () async {
      AuthState? auth = const AuthState(
        accessToken: 'a',
        refreshToken: 'r',
        role: AuthRole.guest,
      );
      final h = buildHarness(authReader: () => auth);

      h.dioAdapter.onGet('/z', (s) => s.reply(401, {}));

      await expectLater(
        h.dio.get<dynamic>(
          '/z',
          options: Options(extra: {'_retried': true}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(h.saveSpy.calls, 0);
      expect(h.clearSpy.calls, 1);
    });
  });
}
