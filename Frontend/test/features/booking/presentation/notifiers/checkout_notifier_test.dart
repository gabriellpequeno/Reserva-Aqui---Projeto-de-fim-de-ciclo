import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reservaqui/features/booking/data/services/booking_service.dart';
import 'package:reservaqui/features/booking/domain/models/hospede_info.dart';
import 'package:reservaqui/features/booking/domain/models/pagamento_fake_model.dart';
import 'package:reservaqui/features/booking/domain/models/reserva_model.dart';
import 'package:reservaqui/features/booking/presentation/notifiers/checkout_notifier.dart';
import 'package:reservaqui/features/rooms/domain/models/hotel_details.dart';

class _MockBookingService extends Mock implements BookingService {}

CategoriaHotelModel _categoria({int capacidade = 2, double preco = 100}) =>
    CategoriaHotelModel(
      id: 1,
      nome: 'Suíte',
      capacidadePessoas: capacidade,
      preco: preco,
      itens: const [],
    );

ReservaModel _reservaFake() => ReservaModel(
      id: 42,
      codigoPublico: 'RES-42',
      numHospedes: 2,
      dataCheckin: DateTime(2026, 5, 12),
      dataCheckout: DateTime(2026, 5, 15),
      valorTotal: 300,
      status: 'SOLICITADA',
      criadoEm: DateTime(2026, 5, 10),
    );

PagamentoFakeModel _pagamentoFake() => const PagamentoFakeModel(
      id: 99,
      reservaId: 42,
      codigoPublico: 'RES-42',
      status: 'PENDENTE',
      valorTotal: 300,
    );

HospedeInfoFormData _hospede() => const HospedeInfoFormData(
      nome: 'Maria Silva',
      email: 'maria@x.com',
      cpf: '52998224725',
      telefone: '11999887766',
    );

void main() {
  setUpAll(() {
    // Registra fallbacks para tipos usados em argumentos do mock.
    registerFallbackValue(_hospede());
  });

  group('CheckoutState.copyWith', () {
    test('preserva campos quando nenhum argumento é passado', () {
      const s = CheckoutState(isLoadingData: false, isAuthenticated: true);
      final c = s.copyWith();
      expect(c.isLoadingData, isFalse);
      expect(c.isAuthenticated, isTrue);
    });

    test('errorMessage é sobreposto quando passado', () {
      const s = CheckoutState();
      expect(s.copyWith(errorMessage: 'boom').errorMessage, 'boom');
    });

    test('clearError força errorMessage para null mesmo passando outro valor', () {
      const s = CheckoutState(errorMessage: 'antigo');
      final c = s.copyWith(errorMessage: 'novo', clearError: true);
      expect(c.errorMessage, isNull);
    });

    test('disponivel pode ser sobrescrito de null para true', () {
      const s = CheckoutState();
      expect(s.copyWith(disponivel: true).disponivel, isTrue);
    });

    test('clearDisponibilidade força disponivel para null', () {
      const s = CheckoutState(disponivel: true);
      final c = s.copyWith(clearDisponibilidade: true);
      expect(c.disponivel, isNull);
    });

    test('clearDisponibilidade tem precedência sobre o argumento disponivel', () {
      const s = CheckoutState(disponivel: false);
      final c = s.copyWith(disponivel: true, clearDisponibilidade: true);
      expect(c.disponivel, isNull);
    });
  });

  group('CheckoutNotifier (sem auth)', () {
    late _MockBookingService booking;
    late ProviderContainer container;
    late CheckoutNotifier notifier;

    setUp(() {
      booking = _MockBookingService();
      container = ProviderContainer(overrides: [
        bookingServiceProvider.overrideWithValue(booking),
      ]);
      addTearDown(container.dispose);

      notifier = container.read(checkoutNotifierProvider.notifier);
    });

    test('estado inicial é o default vazio', () {
      final s = container.read(checkoutNotifierProvider);
      expect(s.isLoadingData, isTrue);
      expect(s.errorMessage, isNull);
      expect(s.categoria, isNull);
      expect(s.reserva, isNull);
      expect(s.pagamento, isNull);
      expect(s.disponivel, isNull);
    });

    group('verificarDisponibilidade', () {
      test('happy path: dispara onSuccess(true), state.disponivel=true e sem erro', () async {
        when(() => booking.fetchDisponibilidade(
              hotelId: any(named: 'hotelId'),
              categoriaId: any(named: 'categoriaId'),
              dataCheckin: any(named: 'dataCheckin'),
              dataCheckout: any(named: 'dataCheckout'),
              onSuccess: any(named: 'onSuccess'),
              onError: any(named: 'onError'),
            )).thenAnswer((invocation) async {
          final cb = invocation.namedArguments[#onSuccess] as void Function(bool);
          cb(true);
        });

        await notifier.verificarDisponibilidade(
          hotelId: 'h1',
          categoriaId: 1,
          checkin: DateTime(2026, 5, 12),
          checkout: DateTime(2026, 5, 15),
        );

        final s = container.read(checkoutNotifierProvider);
        expect(s.isCheckingDisponibilidade, isFalse);
        expect(s.disponivel, isTrue);
        expect(s.errorMessage, isNull);
      });

      test('erro: dispara onError(msg), state guarda errorMessage', () async {
        when(() => booking.fetchDisponibilidade(
              hotelId: any(named: 'hotelId'),
              categoriaId: any(named: 'categoriaId'),
              dataCheckin: any(named: 'dataCheckin'),
              dataCheckout: any(named: 'dataCheckout'),
              onSuccess: any(named: 'onSuccess'),
              onError: any(named: 'onError'),
            )).thenAnswer((invocation) async {
          final cb = invocation.namedArguments[#onError] as void Function(String);
          cb('servidor fora do ar');
        });

        await notifier.verificarDisponibilidade(
          hotelId: 'h1',
          categoriaId: 1,
          checkin: DateTime(2026, 5, 12),
          checkout: DateTime(2026, 5, 15),
        );

        final s = container.read(checkoutNotifierProvider);
        expect(s.isCheckingDisponibilidade, isFalse);
        expect(s.disponivel, isFalse);
        expect(s.errorMessage, 'servidor fora do ar');
      });

      test('formata as datas como YYYY-MM-DD ao chamar o service', () async {
        when(() => booking.fetchDisponibilidade(
              hotelId: any(named: 'hotelId'),
              categoriaId: any(named: 'categoriaId'),
              dataCheckin: any(named: 'dataCheckin'),
              dataCheckout: any(named: 'dataCheckout'),
              onSuccess: any(named: 'onSuccess'),
              onError: any(named: 'onError'),
            )).thenAnswer((_) async {});

        await notifier.verificarDisponibilidade(
          hotelId: 'h1',
          categoriaId: 1,
          checkin: DateTime(2026, 5, 5),
          checkout: DateTime(2026, 5, 9),
        );

        final captured = verify(() => booking.fetchDisponibilidade(
              hotelId: 'h1',
              categoriaId: 1,
              dataCheckin: captureAny(named: 'dataCheckin'),
              dataCheckout: captureAny(named: 'dataCheckout'),
              onSuccess: any(named: 'onSuccess'),
              onError: any(named: 'onError'),
            )).captured;
        expect(captured, ['2026-05-05', '2026-05-09']);
      });
    });

    group('confirmarEGerarPagamento — early returns', () {
      test('returns false quando state.categoria é null (sem efeito colateral)', () async {
        final ok = await notifier.confirmarEGerarPagamento(
          hotelId: 'h1',
          categoriaId: 1,
          quartoId: 1,
          checkin: DateTime(2026, 5, 12),
          checkout: DateTime(2026, 5, 15),
          numHospedes: 2,
          hospedeData: _hospede(),
        );

        expect(ok, isFalse);
        verifyNever(() => booking.createReserva(
              hotelId: any(named: 'hotelId'),
              quartoId: any(named: 'quartoId'),
              tipoQuarto: any(named: 'tipoQuarto'),
              numHospedes: any(named: 'numHospedes'),
              dataCheckin: any(named: 'dataCheckin'),
              dataCheckout: any(named: 'dataCheckout'),
              valorTotal: any(named: 'valorTotal'),
              hospede: any(named: 'hospede'),
              onSuccess: any(named: 'onSuccess'),
              onError: any(named: 'onError'),
            ));
      });
    });

    group('confirmarPagamento / cancelarPagamento sem reserva ou pagamento', () {
      test('confirmarPagamento retorna mensagem específica quando state está vazio', () async {
        final msg = await notifier.confirmarPagamento(PaymentMethod.pix);
        expect(msg, contains('Estado inválido'));
      });

      test('cancelarPagamento retorna mensagem específica quando state está vazio', () async {
        final msg = await notifier.cancelarPagamento();
        expect(msg, contains('nada a cancelar'));
      });
    });

    group('clearError', () {
      test('limpa errorMessage existente', () async {
        // Força erro via verificarDisponibilidade
        when(() => booking.fetchDisponibilidade(
              hotelId: any(named: 'hotelId'),
              categoriaId: any(named: 'categoriaId'),
              dataCheckin: any(named: 'dataCheckin'),
              dataCheckout: any(named: 'dataCheckout'),
              onSuccess: any(named: 'onSuccess'),
              onError: any(named: 'onError'),
            )).thenAnswer((invocation) async {
          final cb = invocation.namedArguments[#onError] as void Function(String);
          cb('boom');
        });

        await notifier.verificarDisponibilidade(
          hotelId: 'h1',
          categoriaId: 1,
          checkin: DateTime(2026, 5, 12),
          checkout: DateTime(2026, 5, 15),
        );
        expect(container.read(checkoutNotifierProvider).errorMessage, 'boom');

        notifier.clearError();
        expect(container.read(checkoutNotifierProvider).errorMessage, isNull);
      });
    });
  });

  // Documentação: confirmarEGerarPagamento happy-path requer state.categoria,
  // que vem de loadData(). loadData() lê authProvider (AsyncNotifierProvider
  // com SharedPreferences + Firebase no build()), o que exige TestWidgetsFlutterBinding.
  // O caminho é coberto em integração no app — ficar aqui só atrapalha.
  // Ver PLANO_TESTES.md §7 sobre AuthNotifier.
  // ignore: dead_code
  void _placeholder() {
    _reservaFake();
    _pagamentoFake();
    _categoria();
  }
}
