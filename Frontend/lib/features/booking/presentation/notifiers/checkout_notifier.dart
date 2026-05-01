import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/rooms/domain/models/hotel_details.dart';
import '../../data/services/booking_service.dart';
import '../../domain/models/reserva_model.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

class CheckoutState {
  final bool isLoadingData;
  final bool isConfirming;
  final String? errorMessage;
  final CategoriaHotelModel? categoria;
  final double? valorDiaria;
  final PoliticasHotelModel? politicas;
  final ReservaModel? reserva;
  final bool reservaCreated;

  const CheckoutState({
    this.isLoadingData = false,
    this.isConfirming = false,
    this.errorMessage,
    this.categoria,
    this.valorDiaria,
    this.politicas,
    this.reserva,
    this.reservaCreated = false,
  });

  CheckoutState copyWith({
    bool? isLoadingData,
    bool? isConfirming,
    String? errorMessage,
    CategoriaHotelModel? categoria,
    double? valorDiaria,
    PoliticasHotelModel? politicas,
    ReservaModel? reserva,
    bool? reservaCreated,
    bool clearError = false,
  }) {
    return CheckoutState(
      isLoadingData: isLoadingData ?? this.isLoadingData,
      isConfirming: isConfirming ?? this.isConfirming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      categoria: categoria ?? this.categoria,
      valorDiaria: valorDiaria ?? this.valorDiaria,
      politicas: politicas ?? this.politicas,
      reserva: reserva ?? this.reserva,
      reservaCreated: reservaCreated ?? this.reservaCreated,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<void> loadData(String hotelId, int categoriaId, int quartoId) async {
    state = state.copyWith(isLoadingData: true, clearError: true, reservaCreated: false);

    CategoriaHotelModel? categoria;
    double? valorDiaria;
    PoliticasHotelModel? politicas;
    String? error;

    final service = ref.read(bookingServiceProvider);

    await Future.wait([
      service.fetchCategoria(
        hotelId: hotelId,
        categoriaId: categoriaId,
        onSuccess: (c) => categoria = c,
        onError: (e) => error = e,
      ),
      service.fetchQuartoPreco(
        hotelId: hotelId,
        quartoId: quartoId,
        onSuccess: (v) => valorDiaria = v,
        onError: (_) {},
      ),
      service.fetchConfiguracao(
        hotelId: hotelId,
        onSuccess: (p) => politicas = p,
        onError: (_) {},
      ),
    ]);

    state = state.copyWith(
      isLoadingData: false,
      categoria: categoria,
      valorDiaria: valorDiaria,
      politicas: politicas,
      errorMessage: error,
    );
  }

  Future<void> confirm({
    required String hotelId,
    required int categoriaId,
    required int quartoId,
    required DateTime checkin,
    required DateTime checkout,
    required int numHospedes,
  }) async {
    if (state.categoria == null) return;

    final capacidade = state.categoria!.capacidadePessoas;
    if (numHospedes > capacidade) {
      state = state.copyWith(
        errorMessage:
            'Este quarto comporta no máximo $capacidade hóspede(s).',
      );
      return;
    }

    state = state.copyWith(isConfirming: true, clearError: true);

    final service = ref.read(bookingServiceProvider);
    final fmt = _fmtDate;

    bool disponivel = false;
    String? availError;

    await service.fetchDisponibilidade(
      hotelId: hotelId,
      categoriaId: categoriaId,
      dataCheckin: fmt(checkin),
      dataCheckout: fmt(checkout),
      onSuccess: (v) => disponivel = v,
      onError: (e) => availError = e,
    );

    if (availError != null) {
      state = state.copyWith(isConfirming: false, errorMessage: availError);
      return;
    }

    if (!disponivel) {
      state = state.copyWith(
        isConfirming: false,
        errorMessage: 'Quarto indisponível nas datas selecionadas.',
      );
      return;
    }

    final numDias = checkout.difference(checkin).inDays;
    final preco = state.valorDiaria ?? state.categoria!.preco;
    final valorTotal = preco * numDias;

    ReservaModel? reserva;
    String? reservaError;

    await service.createReserva(
      hotelId: hotelId,
      quartoId: quartoId,
      tipoQuarto: state.categoria!.nome,
      numHospedes: numHospedes,
      dataCheckin: fmt(checkin),
      dataCheckout: fmt(checkout),
      valorTotal: valorTotal,
      onSuccess: (r) => reserva = r,
      onError: (e) => reservaError = e,
    );

    if (reservaError != null) {
      state = state.copyWith(isConfirming: false, errorMessage: reservaError);
      return;
    }

    state = state.copyWith(
      isConfirming: false,
      reserva: reserva,
      reservaCreated: true,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final checkoutNotifierProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
