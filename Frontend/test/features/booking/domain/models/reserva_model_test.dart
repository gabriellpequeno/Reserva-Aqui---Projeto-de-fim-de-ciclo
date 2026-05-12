import 'package:flutter_test/flutter_test.dart';
import 'package:reservaqui/features/booking/domain/models/reserva_model.dart';

Map<String, dynamic> _validJson() => {
      'id': 42,
      'codigo_publico': 'RES-2026-0042',
      'user_id': 'u-1',
      'nome_hospede': 'Maria Silva',
      'quarto_id': 7,
      'tipo_quarto': 'Suíte',
      'num_hospedes': 2,
      'data_checkin': '2026-05-12',
      'data_checkout': '2026-05-15',
      'valor_total': '450.00',
      'observacoes': 'Chegada tardia',
      'status': 'APROVADA',
      'criado_em': '2026-05-10T14:30:00.000Z',
    };

void main() {
  group('ReservaModel.fromJson', () {
    test('parses a fully populated payload', () {
      final r = ReservaModel.fromJson(_validJson());

      expect(r.id, 42);
      expect(r.codigoPublico, 'RES-2026-0042');
      expect(r.userId, 'u-1');
      expect(r.nomeHospede, 'Maria Silva');
      expect(r.quartoId, 7);
      expect(r.tipoQuarto, 'Suíte');
      expect(r.numHospedes, 2);
      expect(r.dataCheckin, DateTime.parse('2026-05-12'));
      expect(r.dataCheckout, DateTime.parse('2026-05-15'));
      expect(r.valorTotal, 450.00);
      expect(r.observacoes, 'Chegada tardia');
      expect(r.status, 'APROVADA');
      expect(r.criadoEm.isUtc, isTrue);
    });

    test('parses valor_total as numeric (double) when backend returns a number', () {
      final json = _validJson()..['valor_total'] = 1234.56;
      final r = ReservaModel.fromJson(json);
      expect(r.valorTotal, 1234.56);
    });

    test('parses valor_total as integer when backend returns int', () {
      final json = _validJson()..['valor_total'] = 100;
      final r = ReservaModel.fromJson(json);
      expect(r.valorTotal, 100.0);
    });

    test('parses valor_total as string with decimal point', () {
      final json = _validJson()..['valor_total'] = '99.90';
      final r = ReservaModel.fromJson(json);
      expect(r.valorTotal, 99.90);
    });

    test('preserves unknown status values (status is a String typedef)', () {
      // status é typedef String, então qualquer valor passa cru.
      // Documenta o contrato: o app não rejeita status novos do backend.
      final json = _validJson()..['status'] = 'STATUS_NOVO_DESCONHECIDO';
      final r = ReservaModel.fromJson(json);
      expect(r.status, 'STATUS_NOVO_DESCONHECIDO');
    });

    test('accepts null in optional fields', () {
      final json = _validJson()
        ..['user_id'] = null
        ..['nome_hospede'] = null
        ..['quarto_id'] = null
        ..['tipo_quarto'] = null
        ..['observacoes'] = null;
      final r = ReservaModel.fromJson(json);
      expect(r.userId, isNull);
      expect(r.nomeHospede, isNull);
      expect(r.quartoId, isNull);
      expect(r.tipoQuarto, isNull);
      expect(r.observacoes, isNull);
    });

    test('accepts ISO timestamp with timezone for criado_em', () {
      final json = _validJson()..['criado_em'] = '2026-05-10T14:30:00-03:00';
      final r = ReservaModel.fromJson(json);
      expect(r.criadoEm, DateTime.parse('2026-05-10T14:30:00-03:00'));
    });

    test('throws when required field id is missing', () {
      final json = _validJson()..remove('id');
      expect(() => ReservaModel.fromJson(json), throwsA(anything));
    });

    test('throws when codigo_publico is missing', () {
      final json = _validJson()..remove('codigo_publico');
      expect(() => ReservaModel.fromJson(json), throwsA(anything));
    });

    test('throws when data_checkin is not a parseable ISO string', () {
      final json = _validJson()..['data_checkin'] = '12/05/2026';
      expect(() => ReservaModel.fromJson(json), throwsA(anything));
    });

    test('throws when num_hospedes is missing', () {
      final json = _validJson()..remove('num_hospedes');
      expect(() => ReservaModel.fromJson(json), throwsA(anything));
    });
  });
}
