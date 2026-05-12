import 'package:flutter_test/flutter_test.dart';
import 'package:reservaqui/features/rooms/domain/models/reserva_hotel.dart';
import 'package:reservaqui/features/rooms/domain/services/availability_calculator.dart';

ReservaHotelModel _r({
  int id = 1,
  int? quartoId,
  String? tipoQuarto,
  required String checkin,
  required String checkout,
  String status = 'APROVADA',
}) {
  return ReservaHotelModel(
    id: id,
    quartoId: quartoId,
    tipoQuarto: tipoQuarto,
    dataCheckin: DateTime.parse(checkin),
    dataCheckout: DateTime.parse(checkout),
    status: status,
  );
}

DateTime d(String iso) {
  final parts = iso.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

void main() {
  group('computeDiasIndisponiveis', () {
    test('retorna vazio quando totalUnidades <= 0', () {
      final result = computeDiasIndisponiveis(
        [_r(quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15')],
        [1],
        0,
      );
      expect(result, isEmpty);
    });

    test('retorna vazio quando não há quartoIds', () {
      final result = computeDiasIndisponiveis(
        [_r(quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15')],
        [],
        2,
      );
      expect(result, isEmpty);
    });

    test('retorna vazio quando não há reservas ativas para a categoria', () {
      final result = computeDiasIndisponiveis(
        [_r(quartoId: 99, checkin: '2026-05-12', checkout: '2026-05-15')],
        [1, 2],
        2,
      );
      expect(result, isEmpty);
    });

    test('ignora reservas com status que não contam ocupação', () {
      final result = computeDiasIndisponiveis(
        [
          _r(quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15', status: 'CANCELADA'),
          _r(quartoId: 2, checkin: '2026-05-12', checkout: '2026-05-15', status: 'CONCLUIDA'),
        ],
        [1, 2],
        2,
      );
      expect(result, isEmpty);
    });

    test('checkout é exclusivo: dia do checkout não fica indisponível', () {
      // 1 unidade, 1 reserva 12→15 ocupando 100%. Dias indisponíveis: 12, 13, 14.
      final result = computeDiasIndisponiveis(
        [_r(quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15')],
        [1],
        1,
      );
      expect(result, {d('2026-05-12'), d('2026-05-13'), d('2026-05-14')});
      expect(result.contains(d('2026-05-15')), isFalse);
    });

    test('com 2 unidades e 1 reserva, nenhum dia fica indisponível', () {
      final result = computeDiasIndisponiveis(
        [_r(quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15')],
        [1, 2],
        2,
      );
      expect(result, isEmpty);
    });

    test('com 2 unidades e 2 reservas sobrepostas, dias compartilhados ficam cheios', () {
      // Reserva A: 12→15 (ocupa 12,13,14)
      // Reserva B: 13→16 (ocupa 13,14,15)
      // Total 2 unidades. Dias com ocupação == 2: 13, 14.
      final result = computeDiasIndisponiveis(
        [
          _r(id: 1, quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15'),
          _r(id: 2, quartoId: 2, checkin: '2026-05-13', checkout: '2026-05-16'),
        ],
        [1, 2],
        2,
      );
      expect(result, {d('2026-05-13'), d('2026-05-14')});
    });

    test('reservas adjacentes (sem sobreposição) não somam ocupação', () {
      // A: 12→14 ocupa 12,13. B: 14→16 ocupa 14,15. Nenhum dia compartilhado.
      final result = computeDiasIndisponiveis(
        [
          _r(id: 1, quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-14'),
          _r(id: 2, quartoId: 2, checkin: '2026-05-14', checkout: '2026-05-16'),
        ],
        [1, 2],
        2,
      );
      expect(result, isEmpty);
    });

    test('walk-in BALCAO sem quartoId conta quando categoria bate (case-insensitive + trim)', () {
      final result = computeDiasIndisponiveis(
        [
          _r(quartoId: null, tipoQuarto: '  Suíte Master  ', checkin: '2026-05-12', checkout: '2026-05-15'),
        ],
        [1],
        1,
        nomeCategoria: 'suíte master',
      );
      expect(result, {d('2026-05-12'), d('2026-05-13'), d('2026-05-14')});
    });

    test('walk-in com categoria diferente é ignorado', () {
      final result = computeDiasIndisponiveis(
        [
          _r(quartoId: null, tipoQuarto: 'Standard', checkin: '2026-05-12', checkout: '2026-05-15'),
        ],
        [1],
        1,
        nomeCategoria: 'suíte master',
      );
      expect(result, isEmpty);
    });

    test('walk-in sem nomeCategoria fornecido é ignorado', () {
      final result = computeDiasIndisponiveis(
        [
          _r(quartoId: null, tipoQuarto: 'Suíte Master', checkin: '2026-05-12', checkout: '2026-05-15'),
        ],
        [1],
        1,
      );
      expect(result, isEmpty);
    });

    test('soma reserva por quarto + walk-in da mesma categoria', () {
      // 2 unidades. Reserva no quarto 1 (12→15) + walk-in BALCAO da mesma categoria (12→15).
      // Ambos os dias ficam cheios.
      final result = computeDiasIndisponiveis(
        [
          _r(id: 1, quartoId: 1, checkin: '2026-05-12', checkout: '2026-05-15'),
          _r(id: 2, quartoId: null, tipoQuarto: 'Standard', checkin: '2026-05-12', checkout: '2026-05-15'),
        ],
        [1, 2],
        2,
        nomeCategoria: 'standard',
      );
      expect(result, {d('2026-05-12'), d('2026-05-13'), d('2026-05-14')});
    });
  });
}
