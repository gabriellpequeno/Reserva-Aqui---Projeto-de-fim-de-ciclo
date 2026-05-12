import 'package:flutter_test/flutter_test.dart';
import 'package:reservaqui/features/auth/data/models/auth_response.dart';

void main() {
  group('AuthResponse.fromJson', () {
    test('parses both tokens and papel from data', () {
      final r = AuthResponse.fromJson({
        'data': {'papel': 'usuario'},
        'tokens': {
          'accessToken': 'access.jwt.token',
          'refreshToken': 'refresh.jwt.token',
        },
      });
      expect(r.accessToken, 'access.jwt.token');
      expect(r.refreshToken, 'refresh.jwt.token');
      expect(r.papel, 'usuario');
    });

    test('papel is null when data is absent', () {
      final r = AuthResponse.fromJson({
        'tokens': {
          'accessToken': 'a',
          'refreshToken': 'b',
        },
      });
      expect(r.accessToken, 'a');
      expect(r.refreshToken, 'b');
      expect(r.papel, isNull);
    });

    test('papel is null when data.papel is missing', () {
      final r = AuthResponse.fromJson({
        'data': {'outros': 'campos'},
        'tokens': {'accessToken': 'a', 'refreshToken': 'b'},
      });
      expect(r.papel, isNull);
    });

    test('preserves the admin papel value', () {
      final r = AuthResponse.fromJson({
        'data': {'papel': 'admin'},
        'tokens': {'accessToken': 'a', 'refreshToken': 'b'},
      });
      expect(r.papel, 'admin');
    });

    test('throws when tokens block is missing', () {
      expect(
        () => AuthResponse.fromJson({'data': {'papel': 'usuario'}}),
        throwsA(anything),
      );
    });

    test('throws when accessToken is null', () {
      expect(
        () => AuthResponse.fromJson({
          'tokens': {'accessToken': null, 'refreshToken': 'b'},
        }),
        throwsA(anything),
      );
    });

    test('throws when refreshToken is null', () {
      expect(
        () => AuthResponse.fromJson({
          'tokens': {'accessToken': 'a', 'refreshToken': null},
        }),
        throwsA(anything),
      );
    });
  });
}
