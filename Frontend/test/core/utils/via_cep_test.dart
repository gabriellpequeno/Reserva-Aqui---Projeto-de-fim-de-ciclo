import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:reservaqui/core/utils/via_cep.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
  });

  group('fetchViaCep — input validation (no HTTP)', () {
    test('returns null when CEP has fewer than 8 digits', () async {
      final r = await fetchViaCep('1234567', dio: dio);
      expect(r, isNull);
    });

    test('returns null when CEP has more than 8 digits', () async {
      final r = await fetchViaCep('123456789', dio: dio);
      expect(r, isNull);
    });

    test('returns null for empty string', () async {
      expect(await fetchViaCep('', dio: dio), isNull);
    });

    test('strips non-digits before counting (still rejects if final length != 8)', () async {
      final r = await fetchViaCep('CEP: 1234', dio: dio);
      expect(r, isNull);
    });
  });

  group('fetchViaCep — successful response', () {
    test('parses a valid ViaCep payload into ViaCepResult', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/01310100/json/',
        (server) => server.reply(200, {
          'cep': '01310-100',
          'logradouro': 'Avenida Paulista',
          'bairro': 'Bela Vista',
          'localidade': 'São Paulo',
          'uf': 'SP',
        }),
      );

      final r = await fetchViaCep('01310-100', dio: dio);

      expect(r, isNotNull);
      expect(r!.uf, 'SP');
      expect(r.cidade, 'São Paulo');
      expect(r.bairro, 'Bela Vista');
      expect(r.rua, 'Avenida Paulista');
    });

    test('treats missing optional fields (bairro, logradouro) as empty strings', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/12345678/json/',
        (server) => server.reply(200, {
          'localidade': 'Cidade Sem Logradouro',
          'uf': 'XX',
          // bairro e logradouro ausentes
        }),
      );

      final r = await fetchViaCep('12345678', dio: dio);

      expect(r, isNotNull);
      expect(r!.uf, 'XX');
      expect(r.bairro, '');
      expect(r.rua, '');
    });

    test('strips mask before composing the request URL', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/01310100/json/',
        (server) => server.reply(200, {
          'localidade': 'São Paulo',
          'uf': 'SP',
          'bairro': 'X',
          'logradouro': 'Y',
        }),
      );

      final r = await fetchViaCep('01310-100', dio: dio);
      expect(r, isNotNull);
      expect(r!.cidade, 'São Paulo');
    });
  });

  group('fetchViaCep — non-existent CEP', () {
    test('returns null when ViaCep responds with { erro: true }', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/99999999/json/',
        (server) => server.reply(200, {'erro': true}),
      );
      expect(await fetchViaCep('99999999', dio: dio), isNull);
    });

    test('returns null when ViaCep responds with { erro: "true" } (string)', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/99999999/json/',
        (server) => server.reply(200, {'erro': 'true'}),
      );
      expect(await fetchViaCep('99999999', dio: dio), isNull);
    });

    test('returns null when uf is missing', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/12345678/json/',
        (server) => server.reply(200, {'localidade': 'Cidade'}),
      );
      expect(await fetchViaCep('12345678', dio: dio), isNull);
    });

    test('returns null when localidade is missing', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/12345678/json/',
        (server) => server.reply(200, {'uf': 'SP'}),
      );
      expect(await fetchViaCep('12345678', dio: dio), isNull);
    });
  });

  group('fetchViaCep — network errors', () {
    test('returns null on 5xx response', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/01310100/json/',
        (server) => server.reply(500, {'message': 'internal'}),
      );
      expect(await fetchViaCep('01310100', dio: dio), isNull);
    });

    test('returns null on connection error', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/01310100/json/',
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
            error: 'no internet',
          ),
        ),
      );
      expect(await fetchViaCep('01310100', dio: dio), isNull);
    });

    test('returns null when the response body is not a Map', () async {
      adapter.onGet(
        'https://viacep.com.br/ws/01310100/json/',
        (server) => server.reply(200, 'plain text response'),
      );
      expect(await fetchViaCep('01310100', dio: dio), isNull);
    });
  });
}
