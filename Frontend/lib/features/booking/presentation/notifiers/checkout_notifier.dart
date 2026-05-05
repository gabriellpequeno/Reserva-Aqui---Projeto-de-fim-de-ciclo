import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../features/rooms/domain/models/hotel_details.dart';
import '../../../../utils/Usuario.dart';
import '../../data/services/booking_service.dart';
import '../../domain/models/hospede_info.dart';
import '../../domain/models/pagamento_fake_model.dart';
import '../../domain/models/reserva_model.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

class CheckoutState {
  final bool isLoadingData;
  final bool isConfirming;
  final bool isCheckingDisponibilidade;
  final String? errorMessage;

  final CategoriaHotelModel? categoria;
  final double? valorDiaria;
  final PoliticasHotelModel? politicas;

  final ReservaModel? reserva;
  final PagamentoFakeModel? pagamento;

  /// Disponibilidade verificada para as datas atuais. `null` = não verificado ainda.
  final bool? disponivel;

  /// Datas recebidas via queryParam — travam os campos de data quando presentes.
  final DateTime? initialCheckin;
  final DateTime? initialCheckout;

  /// Dados do user autenticado (para pré-preencher o HospedeInfoForm).
  /// Null = guest ou ainda não carregou.
  final HospedeInfoFormData? initialHospedeData;
  final bool isAuthenticated;

  const CheckoutState({
    this.isLoadingData = true,
    this.isConfirming  = false,
    this.isCheckingDisponibilidade = false,
    this.errorMessage,
    this.categoria,
    this.valorDiaria,
    this.politicas,
    this.reserva,
    this.pagamento,
    this.disponivel,
    this.initialCheckin,
    this.initialCheckout,
    this.initialHospedeData,
    this.isAuthenticated = false,
  });

  CheckoutState copyWith({
    bool? isLoadingData,
    bool? isConfirming,
    bool? isCheckingDisponibilidade,
    String? errorMessage,
    CategoriaHotelModel? categoria,
    double? valorDiaria,
    PoliticasHotelModel? politicas,
    ReservaModel? reserva,
    PagamentoFakeModel? pagamento,
    bool? disponivel,
    DateTime? initialCheckin,
    DateTime? initialCheckout,
    HospedeInfoFormData? initialHospedeData,
    bool? isAuthenticated,
    bool clearError = false,
    bool clearDisponibilidade = false,
  }) {
    return CheckoutState(
      isLoadingData:             isLoadingData             ?? this.isLoadingData,
      isConfirming:              isConfirming              ?? this.isConfirming,
      isCheckingDisponibilidade: isCheckingDisponibilidade ?? this.isCheckingDisponibilidade,
      errorMessage:              clearError ? null : (errorMessage ?? this.errorMessage),
      categoria:                 categoria       ?? this.categoria,
      valorDiaria:               valorDiaria     ?? this.valorDiaria,
      politicas:                 politicas       ?? this.politicas,
      reserva:                   reserva         ?? this.reserva,
      pagamento:                 pagamento       ?? this.pagamento,
      disponivel:                clearDisponibilidade ? null : (disponivel ?? this.disponivel),
      initialCheckin:            initialCheckin    ?? this.initialCheckin,
      initialCheckout:           initialCheckout   ?? this.initialCheckout,
      initialHospedeData:        initialHospedeData ?? this.initialHospedeData,
      isAuthenticated:           isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  /// Carrega dados iniciais em paralelo: categoria, preço, políticas, dados do
  /// user autenticado (se houver) e — se datas foram recebidas via queryParam —
  /// já verifica disponibilidade.
  Future<void> loadData({
    required String hotelId,
    required int categoriaId,
    required int quartoId,
    DateTime? initialCheckin,
    DateTime? initialCheckout,
  }) async {
    state = state.copyWith(
      isLoadingData: true,
      clearError: true,
      initialCheckin: initialCheckin,
      initialCheckout: initialCheckout,
      clearDisponibilidade: true,
    );

    CategoriaHotelModel? categoria;
    double? valorDiaria;
    PoliticasHotelModel? politicas;
    String? error;

    final service = ref.read(bookingServiceProvider);

    final futures = <Future<void>>[
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
    ];

    // Carrega dados do user autenticado (para pré-preencher o form).
    final authAsync = ref.read(authProvider);
    final auth = authAsync.asData?.value;
    final isAuth = auth?.isAuthenticated ?? false;

    HospedeInfoFormData? hospedeInitial;
    if (isAuth) {
      final usuarioService = ref.read(usuarioServiceProvider);
      futures.add(
        usuarioService.getAutenticado(
          onSuccess: (u) {
            hospedeInitial = HospedeInfoFormData(
              nome:     (u['nome_completo'] ?? '').toString(),
              email:    (u['email'] ?? '').toString(),
              cpf:      (u['cpf'] ?? '').toString().replaceAll(RegExp(r'\D'), ''),
              telefone: (u['numero_celular'] ?? '').toString().replaceAll(RegExp(r'\D'), ''),
            );
          },
          onError: (_) {},
        ),
      );
    }

    await Future.wait(futures);

    state = state.copyWith(
      isLoadingData: false,
      categoria: categoria,
      valorDiaria: valorDiaria,
      politicas: politicas,
      errorMessage: error,
      initialHospedeData: hospedeInitial,
      isAuthenticated: isAuth,
    );

    // Se já temos datas, verifica disponibilidade imediatamente
    if (initialCheckin != null && initialCheckout != null) {
      await verificarDisponibilidade(
        hotelId: hotelId,
        categoriaId: categoriaId,
        checkin: initialCheckin,
        checkout: initialCheckout,
      );
    }
  }

  Future<void> verificarDisponibilidade({
    required String hotelId,
    required int categoriaId,
    required DateTime checkin,
    required DateTime checkout,
  }) async {
    state = state.copyWith(
      isCheckingDisponibilidade: true,
      clearDisponibilidade: true,
      clearError: true,
    );

    bool disponivel = false;
    String? error;
    final service = ref.read(bookingServiceProvider);

    await service.fetchDisponibilidade(
      hotelId: hotelId,
      categoriaId: categoriaId,
      dataCheckin:  _fmtDate(checkin),
      dataCheckout: _fmtDate(checkout),
      onSuccess: (v) => disponivel = v,
      onError:   (e) => error = e,
    );

    state = state.copyWith(
      isCheckingDisponibilidade: false,
      disponivel: disponivel,
      errorMessage: error,
    );
  }

  /// Cria a reserva (user ou guest, decidido pelo `isAuthenticated`) e já gera
  /// o pagamento fake. Retorna true se todo o fluxo deu certo; false + errorMessage em caso de falha.
  Future<bool> confirmarEGerarPagamento({
    required String hotelId,
    required int categoriaId,
    required int quartoId,
    required DateTime checkin,
    required DateTime checkout,
    required int numHospedes,
    required HospedeInfoFormData hospedeData,
  }) async {
    if (state.categoria == null) return false;

    if (numHospedes > state.categoria!.capacidadePessoas) {
      state = state.copyWith(
        errorMessage: 'Este quarto comporta no máximo ${state.categoria!.capacidadePessoas} hóspede(s).',
      );
      return false;
    }

    if (state.disponivel == false) {
      state = state.copyWith(errorMessage: 'Quarto indisponível nas datas selecionadas.');
      return false;
    }

    state = state.copyWith(isConfirming: true, clearError: true);
    final service = ref.read(bookingServiceProvider);

    final numDias    = checkout.difference(checkin).inDays;
    final preco      = state.valorDiaria ?? state.categoria!.preco;
    final valorTotal = preco * numDias;

    // 1. Criar reserva
    ReservaModel? reserva;
    String? reservaError;

    if (state.isAuthenticated) {
      // Se editou os dados, passa como hóspede pra terceiro; se não, omite
      final diverged = hospedeData.hasDivergedFrom(state.initialHospedeData);
      await service.createReserva(
        hotelId: hotelId,
        quartoId: quartoId,
        tipoQuarto: state.categoria!.nome,
        numHospedes: numHospedes,
        dataCheckin:  _fmtDate(checkin),
        dataCheckout: _fmtDate(checkout),
        valorTotal: valorTotal,
        hospede: diverged ? hospedeData : null,
        onSuccess: (r) => reserva = r,
        onError:   (e) => reservaError = e,
      );
    } else {
      await service.createReservaGuest(
        hotelId: hotelId,
        quartoId: quartoId,
        categoriaId: categoriaId,
        tipoQuarto: state.categoria!.nome,
        numHospedes: numHospedes,
        dataCheckin:  _fmtDate(checkin),
        dataCheckout: _fmtDate(checkout),
        valorTotal: valorTotal,
        hospede: hospedeData,
        onSuccess: (r) => reserva = r,
        onError:   (e) => reservaError = e,
      );
    }

    if (reservaError != null || reserva == null) {
      state = state.copyWith(isConfirming: false, errorMessage: reservaError ?? 'Falha ao criar reserva.');
      return false;
    }

    // 2. Gerar pagamento
    PagamentoFakeModel? pagamento;
    String? pagError;

    await service.createPagamento(
      codigoPublico: reserva!.codigoPublico,
      canal: 'APP',
      onSuccess: (p) => pagamento = p,
      onError:   (e) => pagError = e,
    );

    if (pagError != null || pagamento == null) {
      state = state.copyWith(isConfirming: false, errorMessage: pagError ?? 'Falha ao gerar pagamento.');
      return false;
    }

    state = state.copyWith(
      isConfirming: false,
      reserva: reserva,
      pagamento: pagamento,
    );
    return true;
  }

  /// Confirma o pagamento fake escolhendo a modalidade.
  /// Retorna `null` em sucesso; mensagem de erro específica em falha.
  Future<String?> confirmarPagamento(PaymentMethod metodo) async {
    final pag = state.pagamento;
    final res = state.reserva;
    if (pag == null || res == null) {
      return 'Estado inválido — reserva ou pagamento ausente. Tente reiniciar o fluxo.';
    }

    final service = ref.read(bookingServiceProvider);
    PagamentoFakeModel? atualizado;
    String? error;

    await service.confirmarPagamento(
      codigoPublico: res.codigoPublico,
      pagamentoId:   pag.id,
      metodo:        metodo,
      onSuccess:     (p) => atualizado = p,
      onError:       (e) => error = e,
    );

    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return error;
    }
    state = state.copyWith(pagamento: atualizado);
    return null;
  }

  /// Cancela pagamento + reserva. Retorna `null` em sucesso; mensagem em falha.
  Future<String?> cancelarPagamento() async {
    final pag = state.pagamento;
    final res = state.reserva;
    if (pag == null || res == null) {
      return 'Estado inválido — nada a cancelar.';
    }

    final service = ref.read(bookingServiceProvider);
    String? error;

    await service.cancelarPagamento(
      codigoPublico: res.codigoPublico,
      pagamentoId:   pag.id,
      onSuccess:     (_) {},
      onError:       (e) => error = e,
    );

    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return error;
    }
    return null;
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final checkoutNotifierProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
